c_url = "http://127.0.0.1:3000/plant/index";
c_response = await fetch(c_url, {
    method: "GET", // *GET, POST, PUT, DELETE, etc.
    mode: "cors", // no-cors, *cors, same-origin
    cache: "no-cache", // *default, no-cache, reload, force-cache, only-if-cached
    credentials: "same-origin", // include, *same-origin, omit
    headers: {
      "Content-Type": "application/json",
      "X-Plant-Custom-Bits": "value from client"
    },
    redirect: "follow"
});
