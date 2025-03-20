return {
    Name = "SPOTIFY LOBBY",
    Description = '• Feito por <font color="#FFA500">Rhyan57\n</font> MAN WANTS TO LISTEN TO MUSIC IN THE LOBBY.',
    Elements = {
        {
            Type = "Label",
            Arguments = { Text = '<font color="#9DABFF">CLIQUE ABAIXO</font>' }
        },
        {
            Type = "Button",
            Arguments = {
                Text = "DOWNLOAD SONGS",
                Callback = function() 
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/Sc-Rhyan57/MsProject/refs/heads/main/projects/doors-lobby-spotify.lua"))()
                end
            }
        }
    }
}
