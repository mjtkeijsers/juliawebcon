import Pkg;
Pkg.add("HTTP")
Pkg.add("Dates")

using HTTP, Sockets, Dates

const PAGE = raw"""
<!doctype html>
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
      gap: 1.25rem;
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
      width: min(78vw, 62vh, 560px);
      aspect-ratio: 1;
      padding: clamp(8px, 2vw, 14px);
      border: 1px solid #29445b;
      border-radius: 18px;
      background: #0a1724;
      box-shadow: 0 24px 80px #0008, 0 0 42px #39d9b51a;
    }
    canvas { display: block; width: 100%; height: 100%; border-radius: 8px; }
    .status { margin: 0; color: #a8bdd0; font-size: .9rem; }
    .status strong { color: #65e6c2; font-variant-numeric: tabular-nums; }
    .controls { display: flex; flex-wrap: wrap; justify-content: center; gap: .7rem; }
    button {
      min-width: 116px;
      padding: .7rem 1rem;
      border: 1px solid #38566c;
      border-radius: 999px;
      background: #112538;
      color: #e5f2ff;
      font: inherit;
      cursor: pointer;
      transition: background .15s ease, border-color .15s ease, transform .15s ease;
    }
    button:hover { border-color: #65e6c2; background: #17374a; }
    button:active { transform: translateY(1px); }
    button:focus-visible { outline: 2px solid #65e6c2; outline-offset: 3px; }
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
    .text-column h2 { font-size: .8rem; }
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
    .text-entry:focus { border-color: #65e6c2; outline: 2px solid #65e6c233; }
    .text-result {
      min-height: 46px;
      overflow-wrap: anywhere;
      color: #65e6c2;
    }
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
    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after { scroll-behavior: auto !important; }
    }
  </style>
</head>
<body>
  <main>
    <header>
      <p class="eyebrow">A tiny universe</p>
      <h1>Conway's Game of Life</h1>
      <p class="subtitle">Simple rules. Unexpected worlds.</p>
    </header>
    <div class="board">
      <canvas id="life" aria-label="Animated Conway's Game of Life grid"></canvas>
    </div>
    <p class="status" aria-live="polite">Generation <strong id="generation">0</strong> · <span id="population">0</span> living cells</p>
    <div class="controls">
      <button id="toggle" type="button">Pause</button>
      <button id="restart" type="button">New world</button>
    </div>
    <section class="text-panel" aria-label="Timestamped text">
      <div class="text-column">
        <label for="text-entry">Type a message and press Enter</label>
        <form id="text-form">
          <input id="text-entry" class="text-entry" type="text" maxlength="500" autocomplete="off" placeholder="Your text…" required>
        </form>
      </div>
      <div class="text-column">
        <h2>Last entry</h2>
        <output id="text-result" class="text-result" aria-live="polite">Nothing entered yet.</output>
      </div>
    </section>
    <p class="hint">Click any cell to bring it to life (or let it rest).</p>
  </main>
  <script>
    (() => {
      const size = 48;
      const canvas = document.getElementById("life");
      const context = canvas.getContext("2d");
      const generationLabel = document.getElementById("generation");
      const populationLabel = document.getElementById("population");
      const toggleButton = document.getElementById("toggle");
      let cells = makeWorld();
      let generation = 0;
      let running = !window.matchMedia("(prefers-reduced-motion: reduce)").matches;

      function makeWorld() {
        return Array.from({ length: size }, () =>
          Array.from({ length: size }, () => Math.random() < 0.22 ? 1 : 0)
        );
      }

      function draw() {
        const scale = window.devicePixelRatio || 1;
        const bounds = canvas.getBoundingClientRect();
        const side = Math.max(1, Math.floor(bounds.width * scale));
        if (canvas.width !== side || canvas.height !== side) {
          canvas.width = side;
          canvas.height = side;
        }
        context.setTransform(scale, 0, 0, scale, 0, 0);
        const cellSize = bounds.width / size;
        context.fillStyle = "#0a1724";
        context.fillRect(0, 0, bounds.width, bounds.width);

        let population = 0;
        for (let y = 0; y < size; y += 1) {
          for (let x = 0; x < size; x += 1) {
            if (!cells[y][x]) continue;
            population += 1;
            context.fillStyle = "#65e6c2";
            context.fillRect(
              x * cellSize + 1,
              y * cellSize + 1,
              Math.max(1, cellSize - 2),
              Math.max(1, cellSize - 2)
            );
          }
        }
        generationLabel.textContent = generation.toLocaleString();
        populationLabel.textContent = population.toLocaleString();
      }

      function advance() {
        cells = cells.map((row, y) => row.map((alive, x) => {
          let neighbors = 0;
          for (let dy = -1; dy <= 1; dy += 1) {
            for (let dx = -1; dx <= 1; dx += 1) {
              if (dx === 0 && dy === 0) continue;
              const ny = (y + dy + size) % size;
              const nx = (x + dx + size) % size;
              neighbors += cells[ny][nx];
            }
          }
          return neighbors === 3 || (alive && neighbors === 2) ? 1 : 0;
        }));
        generation += 1;
        draw();
      }

      canvas.addEventListener("click", event => {
        const bounds = canvas.getBoundingClientRect();
        const x = Math.floor((event.clientX - bounds.left) / bounds.width * size);
        const y = Math.floor((event.clientY - bounds.top) / bounds.height * size);
        if (x >= 0 && x < size && y >= 0 && y < size) {
          cells[y][x] = cells[y][x] ? 0 : 1;
          draw();
        }
      });
      toggleButton.addEventListener("click", () => {
        running = !running;
        toggleButton.textContent = running ? "Pause" : "Resume";
      });
      toggleButton.textContent = running ? "Pause" : "Resume";
      document.getElementById("text-form").addEventListener("submit", event => {
        event.preventDefault();
        const input = document.getElementById("text-entry");
        const text = input.value;
        if (!text.trim()) return;

        const enteredAt = new Date();
        const result = document.getElementById("text-result");
        const time = document.createElement("time");
        time.dateTime = enteredAt.toISOString();
        time.textContent = enteredAt.toLocaleTimeString();
        const message = document.createElement("span");
        message.textContent = text;
        result.replaceChildren(time, message);
        input.value = "";
        input.focus();
      });
      document.getElementById("restart").addEventListener("click", () => {
        cells = makeWorld();
        generation = 0;
        draw();
      });
      window.addEventListener("resize", draw);
      draw();
      window.setInterval(() => { if (running) advance(); }, 120);
    })();
  </script>
</body>
</html>
"""

println("Starting my server ...")

# Write to a file, this file is stored in the dir where
# the julia program runs

# in case program runs in container data is stored inside container
# at /app dir as specified WORKDIR in Dockerfile

# To persist the data file over container sessions:
# create a 'volume' : docker volume create myvolumename
#
# Then start the container by binding the /app dir in container to
# myvolumename: docker run -v myvolumename:/app -p 80:80 juliacon
open("serverlocalstorage.txt", "a") do io
       write(io, "Start the server\n")
   end;

HTTP.listen("0.0.0.0", 80) do http
    println("Caught the next request ..." )

    d_now = Dates.format(now(), "HH:MM:SS")

    #if desired can see into the container via
    # docker exec -t -i mycontainer_id /bin/bash
    open("serverlocalstorage.txt", "a") do io
           write(io, "Serving a request\n")
           write(io, d_now)
           write(io, "----\n")
    end;

    HTTP.setheader(http, "Content-Type" => "text/html; charset=utf-8")
    write(http, PAGE)
    return
end
