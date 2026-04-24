let count = 0;

document.addEventListener("DOMContentLoaded", () => {
  const button = document.getElementById("clickMe");
  const counter = document.getElementById("counter");

  button.addEventListener("click", () => {
    count += 1;
    counter.textContent = `Clicks: ${count}`;
  });
});
