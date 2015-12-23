var timediff;
var empxWidth;
var width;

window.onload = function(){
    empxWidth = parseInt(document.defaultView.getComputedStyle(document.getElementById("emScale"), null).getPropertyValue("width"));
    var servertime = parseInt(document.getElementById('servertime').textContent);
    var browsertime = parseInt((new Date)/1000);
    timediff = browsertime - servertime;

    width = parseInt(document.defaultView.getComputedStyle(document.getElementsByClassName("item")[0], null).getPropertyValue("width")) / empxWidth * 2;
    
    update();
    setInterval("update()", 1000);
}

function update(){
    var browsertime = parseInt((new Date)/1000);
    
    var elements = document.getElementsByClassName('timebar');
    for(var i=0; i<elements.length; i++){
        var ele = elements.item(i);
        var par = ele.parentNode;

        var starttime = parseInt(par.getElementsByClassName('starttimeunix').item(0).textContent) + timediff;
        var endtime = parseInt(par.getElementsByClassName('endtimeunix').item(0).textContent) + timediff;


        if(browsertime > endtime){
            window.location.reload();
        }

        var bar = "";
        var current = parseInt((browsertime - starttime) / (endtime - starttime) * (width - 1));
        for(var j=0; j<current; j++){
            bar += "-";
        }
        bar += "I";
        for(var j=current+1; j<width; j++){
            bar += "-";
        }
        
        ele.textContent = bar;
    }
}

function skip(mountpoint){
    var request = new XMLHttpRequest();
    request.onreadystatechange = function() {
        if (request.readyState == 4 && request.status == 200) {
            window.location.reload();
        }
    }
    request.open("GET", "/skip/" + mountpoint, true);
    request.send("");
    alert("skipping...");
}


function request(mountpoint){
    var request = new XMLHttpRequest();
    request.onreadystatechange = function() {
        // if (request.readyState == 4 && request.status == 200) {
        //     window.location.reload();
        // }
    }
    req = window.prompt("please input request song or word");
    if(req != ""){
        request.open("GET", "/request/" + mountpoint + "/" + req, true);
        request.send("");
        //alert("sending...");
    }
}
