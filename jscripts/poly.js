function setFunctionText() {
    var sel = document.getElementById("selectFunction");
    var option = sel.selectedIndex;
    if (option == 0)
        document.getElementById("functionText").value = "";
    else {
       var f = document.getElementById("functionTexts").children[option-1];
       var text = f.innerHTML;
       document.getElementById("functionText").value = text;
       
    }
  
}
