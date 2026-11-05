-- Layer surfaces of the desktop shell (glyph): blur on, Hyprland's own layer animations off (the shell animates itself),
-- no blur behind the shell's panels (blur behind animated panels stalls the GPU).

hl.config({
    decoration = {
        blur = {
            enabled = true,
        },
    },
})

hl.animation({ leaf = "layers", enabled = false })

hl.layer_rule({ match = { namespace = "^glyph-.*$" }, blur = false })
hl.layer_rule({ match = { namespace = "^gtk-layer-shell$" }, blur = false })
