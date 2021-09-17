

function loadSettings() {
	if (localStorage.getItem("serverAddress") === null) {
		var helpText = "http://ServerURL";
	} else {
		var helpText = localStorage.getItem("serverAddress");
	}
	var newAddress = prompt("Enter Server Address", helpText);
	if (newAddress == null || newAddress == "http://ServerURL" || newAddress == "") {
		//Nothing Done
	} else {
		localStorage.setItem("serverAddress", newAddress); 
		setTimeout(function(){ 
			document.getElementById("client").setAttribute("src", localStorage.getItem("serverAddress")); 
		}, 100);
	}
}

function clearSettings() {
	localStorage.removeItem("serverAddress");
	setTimeout(function(){ 
			document.getElementById("client").setAttribute("src", "../app/noServer.html"); 
	}, 100);
}

function resizeBody() {
	var h = window.innerHeight;
	var w = window.innerWidth;
	console.log(h);
	h = h - 4;
	w = w - 4;
	console.log(h);
	document.getElementById("client").style.height = h;
	document.getElementById("client").style.width = w;
}

var menubar = new nw.Menu({
  type: 'menubar'
});

var settingMenu = new nw.Menu();
settingMenu.append(new nw.MenuItem({
  label: 'Server Address',
  click: function() {
    loadSettings();
  }
}));
settingMenu.append(new nw.MenuItem({
  label: 'Clear Settings',
  click: function() {
    clearSettings();
  }
}));

var helpMenu = new nw.Menu();
helpMenu.append(new nw.MenuItem({
	label :'About',
	click: function() {
		alert('Provided by FikesMedia\n\nFor questions or feature request contact support@fikesmedia.com');
	}
}));

menubar.append(new nw.MenuItem({ label: 'Settings', submenu: settingMenu}));
menubar.append(new nw.MenuItem({ label: 'Help', submenu: helpMenu}));

var win = nw.Window.get();
win.menu = menubar;

window.addEventListener("resize", resizeBody);


if (localStorage.getItem("serverAddress") == null || localStorage.getItem("serverAddress") == "http://ServerURL" || localStorage.getItem("serverAddress") == "") {
		//Nothing Done
} else {
	setTimeout(function(){ 
	
		chrome.contentSettings.plugins.set({
		primaryPattern: "<all_urls>",
		resourceIdentifier: { id: "adobe-flash-player" },
		setting: "allow"
		});

		document.getElementById("client").setAttribute("src", localStorage.getItem("serverAddress")); 
	}, 100);
}
	
	