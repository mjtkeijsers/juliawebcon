using Dates, HTTP, Random

const BOARD_SIZE = 48
const LOG_FILE = "serverlocalstorage.txt"
const SERVER_PORT = parse(Int, get(ENV, "PORT", "80"))

struct GameState
    cells::Matrix{Bool}
    generation::Int
    message::String
    entered_at::String
end

function new_world()
    cells = falses(BOARD_SIZE, BOARD_SIZE)
    for row in 1:BOARD_SIZE, column in 1:BOARD_SIZE
        cells[row, column] = rand() < 0.22
    end
    return cells
end

function next_generation(cells::Matrix{Bool})
    next = falses(BOARD_SIZE, BOARD_SIZE)
    for row in 1:BOARD_SIZE, column in 1:BOARD_SIZE
        neighbors = 0
        for dy in -1:1, dx in -1:1
            if dx != 0 || dy != 0
                neighbor_row = mod1(row + dy, BOARD_SIZE)
                neighbor_column = mod1(column + dx, BOARD_SIZE)
                neighbors += cells[neighbor_row, neighbor_column]
            end
        end
        next[row, column] = neighbors == 3 || (cells[row, column] && neighbors == 2)
    end
    return next
end

function encode_cells(cells::Matrix{Bool})
    return join((cells[row, column] ? '1' : '0'
                 for row in 1:BOARD_SIZE for column in 1:BOARD_SIZE))
end

function decode_cells(encoded::String)
    if ncodeunits(encoded) != BOARD_SIZE^2 || any(cell -> cell != '0' && cell != '1', encoded)
        throw(ArgumentError("Invalid board state."))
    end

    cells = falses(BOARD_SIZE, BOARD_SIZE)
    index = 1
    for row in 1:BOARD_SIZE, column in 1:BOARD_SIZE
        cells[row, column] = encoded[index] == '1'
        index += 1
    end
    return cells
end

function load_state(params::AbstractDict{String,String})
    haskey(params, "board") || throw(ArgumentError("Missing board state."))
    haskey(params, "generation") || throw(ArgumentError("Missing generation number."))

    generation = tryparse(Int, params["generation"])
    if generation === nothing || generation < 0
        throw(ArgumentError("Invalid generation number."))
    end

    return GameState(
        decode_cells(params["board"]),
        generation,
        get(params, "message", ""),
        get(params, "entered_at", ""),
    )
end

function escape_html(value::AbstractString)
    escaped = replace(value, "&" => "&amp;")
    escaped = replace(escaped, "<" => "&lt;")
    escaped = replace(escaped, ">" => "&gt;")
    escaped = replace(escaped, "\"" => "&quot;")
    return replace(escaped, "'" => "&#39;")
end

function write_hidden(io::IO, name::String, value::AbstractString)
    print(io, "<input type=\"hidden\" name=\"", name, "\" value=\"",
          escape_html(value), "\">")
end

function write_state_fields(io::IO, state::GameState)
    write_hidden(io, "board", encode_cells(state.cells))
    write_hidden(io, "generation", string(state.generation))
    write_hidden(io, "message", state.message)
    write_hidden(io, "entered_at", state.entered_at)
end

function render_page(state::GameState)
    io = IOBuffer()
    print(io, raw"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Conway's Game of Life</title>
  <style>
    :root {
      color-scheme: dark;
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #07111f;
      color: #e5f2ff;
    }
    * { box-sizing: border-box; }
    body {
      min-height: 100vh;
      margin: 0;
      display: grid;
      place-items: center;
      padding: 2rem 1rem;
      background: radial-gradient(ellipse at 50% 42%, #142b40 0%, #0b1929 48%, #07111f 100%);
    }
    main {
      width: min(100%, 700px);
      display: grid;
      justify-items: center;
      gap: 1.1rem;
      text-align: center;
    }
    .eyebrow {
      margin: 0 0 .45rem;
      color: #65e6c2;
      font-size: .75rem;
      font-weight: 700;
      letter-spacing: .22em;
      text-transform: uppercase;
    }
    h1 {
      margin: 0;
      font-size: clamp(2rem, 7vw, 3.5rem);
      letter-spacing: -.045em;
    }
    .subtitle { margin: .65rem 0 0; color: #a8bdd0; }
    .board {
      width: min(82vw, 62vh, 560px);
      aspect-ratio: 1;
      padding: clamp(8px, 2vw, 14px);
      border: 1px solid #29445b;
      border-radius: 18px;
      background: #0a1724;
      box-shadow: 0 24px 80px #0008, 0 0 42px #39d9b51a;
    }
    .cells {
      display: grid;
      width: 100%;
      height: 100%;
      grid-template-columns: repeat(48, minmax(0, 1fr));
      overflow: hidden;
      border-radius: 8px;
      background: #0a1724;
    }
    .cell {
      min-width: 0;
      min-height: 0;
      margin: 1px;
      padding: 0;
      border: 0;
      border-radius: 2px;
      background: #122538;
      cursor: pointer;
    }
    .cell.alive { background: #65e6c2; }
    .cell:hover { outline: 1px solid #d0fff3; outline-offset: -1px; }
    .status { margin: 0; color: #a8bdd0; font-size: .9rem; }
    .status strong { color: #65e6c2; font-variant-numeric: tabular-nums; }
    .controls { display: flex; flex-wrap: wrap; justify-content: center; gap: .7rem; }
    button.action {
      min-width: 132px;
      padding: .7rem 1rem;
      border: 1px solid #38566c;
      border-radius: 999px;
      background: #112538;
      color: #e5f2ff;
      font: inherit;
      cursor: pointer;
    }
    button.action:hover { border-color: #65e6c2; background: #17374a; }
    button:focus-visible, input:focus-visible {
      outline: 2px solid #65e6c2;
      outline-offset: 3px;
    }
    .text-panel {
      width: min(100%, 560px);
      display: grid;
      grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
      gap: .8rem;
      text-align: left;
    }
    .text-column { min-width: 0; }
    .text-column label, .text-column h2 {
      display: block;
      margin: 0 0 .45rem;
      color: #a8bdd0;
      font-size: .8rem;
      font-weight: 600;
    }
    .text-entry, .text-result {
      width: 100%;
      min-height: 46px;
      padding: .7rem .8rem;
      border: 1px solid #29445b;
      border-radius: 10px;
      background: #0a1724;
      color: #e5f2ff;
      font: inherit;
    }
    .text-entry:focus { border-color: #65e6c2; }
    .text-result { overflow-wrap: anywhere; color: #65e6c2; }
    .text-result time {
      display: block;
      margin-bottom: .25rem;
      color: #7891a7;
      font-size: .75rem;
    }
    .text-result span { display: block; white-space: pre-wrap; }
    .hint { margin: 0; color: #7891a7; font-size: .8rem; }
    @media (max-width: 520px) {
      .text-panel { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <main>
    <header>
      <p class="eyebrow">A tiny universe</p>
      <h1>Conway's Game of Life</h1>
      <p class="subtitle">Each generation is calculated by Julia.</p>
    </header>
""")
    print(io, "<form method=\"post\" class=\"game-form\">")
    write_state_fields(io, state)
    print(io, "<div class=\"board\"><div class=\"cells\" role=\"group\" aria-label=\"Game of Life board\">")
    population = 0
    for row in 1:BOARD_SIZE, column in 1:BOARD_SIZE
        alive = state.cells[row, column]
        population += alive
        cell_index = (row - 1) * BOARD_SIZE + column
        cell_class = alive ? "cell alive" : "cell"
        label = "Toggle cell $row,$column"
        print(io, "<button type=\"submit\" class=\"", cell_class,
              "\" name=\"cell\" value=\"", cell_index, "\" aria-label=\"",
              label, "\"></button>")
    end
    print(io, "</div></div>")
    print(io, "<p class=\"status\">Generation <strong>", state.generation,
          "</strong> · <span>", population, "</span> living cells</p>")
    print(io, "<div class=\"controls\">",
          "<button class=\"action\" type=\"submit\" name=\"action\" value=\"step\">Advance one generation</button>",
          "<button class=\"action\" type=\"submit\" name=\"action\" value=\"restart\">New world</button>",
          "</div></form>")

    print(io, "<section class=\"text-panel\" aria-label=\"Timestamped text\">")
    print(io, "<div class=\"text-column\"><label for=\"text-entry\">Type a message and press Enter</label>",
          "<form method=\"post\">")
    write_state_fields(io, state)
    print(io, "<input id=\"text-entry\" class=\"text-entry\" type=\"text\" name=\"text\"",
          " maxlength=\"500\" autocomplete=\"off\" placeholder=\"Your text…\" required>")
    print(io, "<button class=\"action\" type=\"submit\" name=\"action\" value=\"save-text\">Save text</button>",
          "</form></div><div class=\"text-column\"><h2>Last entry</h2>",
          "<div class=\"text-result\" aria-live=\"polite\">")
    if isempty(state.message)
        print(io, "Nothing entered yet.")
    else
        print(io, "<time>", escape_html(state.entered_at), "</time><span>",
              escape_html(state.message), "</span>")
    end
    print(io, "</div></div></section>",
          "<p class=\"hint\">Select a cell to toggle it, or advance the simulation one generation.</p>",
          "</main></body></html>")
    return String(take!(io))
end

function response(status::Int, body::AbstractString)
    return HTTP.Response(status, ["Content-Type" => "text/html; charset=utf-8"],
                         body=body)
end

function handle_request(request::HTTP.Request)
    if request.method != "GET" && request.method != "POST"
        return response(405, "Method not allowed.")
    end

    params = request.method == "GET" ?
        HTTP.URIs.queryparams(HTTP.URI(request.target)) :
        HTTP.URIs.queryparams(String(request.body))

    if isempty(params) && request.method == "GET" && request.target == "/"
        return response(200, render_page(GameState(new_world(), 0, "", "")))
    end

    state = try
        load_state(params)
    catch error
        if error isa ArgumentError
            return response(400, escape_html(error.msg))
        end
        rethrow()
    end

    if haskey(params, "cell")
        index = tryparse(Int, params["cell"])
        if index === nothing || index < 1 || index > BOARD_SIZE^2
            return response(400, "Invalid cell selection.")
        end
        row, column = divrem(index - 1, BOARD_SIZE)
        state.cells[row + 1, column + 1] = !state.cells[row + 1, column + 1]
    else
        action = get(params, "action", "")
        if action == "step"
            state = GameState(next_generation(state.cells), state.generation + 1,
                              state.message, state.entered_at)
        elseif action == "restart"
            state = GameState(new_world(), 0, state.message, state.entered_at)
        elseif action == "save-text"
            text = get(params, "text", "")
            if isempty(strip(text)) || ncodeunits(text) > 500
                return response(400, "Text must contain 1 to 500 bytes.")
            end
            state = GameState(state.cells, state.generation, text,
                              Dates.format(now(), "yyyy-mm-dd HH:MM:SS"))
        else
            return response(400, "Unknown action.")
        end
    end

    return response(200, render_page(state))
end

println("Starting Julia Game of Life server on port ", SERVER_PORT, "...")
open(LOG_FILE, "a") do io
    write(io, "Start the server\n")
end

HTTP.serve("0.0.0.0", SERVER_PORT) do request
    timestamp = Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
    open(LOG_FILE, "a") do io
        write(io, "Serving a request at ", timestamp, "\n")
    end
    return handle_request(request)
end
