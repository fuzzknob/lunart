document.getElementById("lunart").addEventListener("click", function () {
    document.getElementById("popup").classList.add("popup-show");
});

document.getElementById("popup").addEventListener("click", function () {
    document.getElementById("popup").classList.remove("popup-show");
});
