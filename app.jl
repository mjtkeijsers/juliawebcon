using HTTP

const LOG_FILE = joinpath(@__DIR__, "data", "serverlocalstorage.txt")
const SERVER_PORT = parse(Int, get(ENV, "PORT", "80"))

function escape_html(value::AbstractString)
    escaped = replace(value, "&" => "&amp;")
    escaped = replace(escaped, "<" => "&lt;")
    escaped = replace(escaped, ">" => "&gt;")
    escaped = replace(escaped, "\"" => "&quot;")
    return replace(escaped, "'" => "&#39;")
end

function render_page(text::AbstractString = "")
    io = IOBuffer()
    print(io, raw"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Text echo</title>
  <style>
    body {
      min-height: 100vh;
      margin: 0;
      display: grid;
      place-items: center;
      background: #101820;
      color: #f0f4f8;
      font: 1rem system-ui, sans-serif;
    }
    main { width: min(32rem, calc(100% - 2rem)); }
    input {
      box-sizing: border-box;
      width: 100%;
      padding: .8rem;
      border: 1px solid #718096;
      border-radius: .4rem;
      font: inherit;
    }
    output { display: block; min-height: 1.5em; margin-top: 1rem; overflow-wrap: anywhere; }
  </style>
</head>
<body>
  <main>
    <form method="post">
      <input id="text" name="text" type="text" maxlength="500" autocomplete="off"
             placeholder="Type text and press Enter" required autofocus value=""")
    print(io, escape_html(text))
    print(io, raw""">
    </form>
    <output id="echo" aria-live="polite">""")
    print(io, escape_html(text))
    print(io, raw"""</output>
  </main>
  <script>
    const text = document.querySelector("#text");
    const echo = document.querySelector("#echo");
    text.addEventListener("input", () => { echo.textContent = text.value; });
  </script>
</body>
</html>""")
    return String(take!(io))
end

function response(status::Int, body::AbstractString)
    return HTTP.Response(status, ["Content-Type" => "text/html; charset=utf-8"],
                         body=body)
end

function handle_request(request::HTTP.Request)
    if request.method == "GET"
        return response(200, render_page())
    elseif request.method != "POST"
        return response(405, "Method not allowed.")
    end

    params = HTTP.URIs.queryparams(String(request.body))
    text = get(params, "text", "")
    if isempty(strip(text)) || ncodeunits(text) > 500
        return response(400, "Text must contain 1 to 500 bytes.")
    end

    mkpath(dirname(LOG_FILE))
    open(LOG_FILE, "a") do io
        write(io, text, '\n')
    end

    return response(200, render_page(text))
end

println("Starting text echo server on port ", SERVER_PORT, "...")

HTTP.serve("0.0.0.0", SERVER_PORT) do request
    return handle_request(request)
end
