var testDiv = document.getElementById("testDiv");
testDiv.addEventListener('click', function f(e) {
    testDiv.setAttribute('style', 'background:red;')
    console.log("style changed");
})