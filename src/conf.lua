function love.conf(t)
	t.title="Roguelove Example"
	t.version="11.2"
	t.author="Weirdfellows"
	t.identity="rogueloveexample"
	t.url="http://weirdfellows.com"

	t.modules.physics=false
	t.window.resizable = true
	t.window.minwidth=1024
	t.window.minheight=720

	if love._os == "NX" then
        t.window.width = 1280
        t.window.height = 720
    end
end