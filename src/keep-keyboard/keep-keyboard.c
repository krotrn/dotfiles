// keep-keyboard: hold one idle virtual keyboard open in the Wayland session.
//
// While the machine sleeps, Hyprland drops every libinput keyboard. With no keyboard left it clears the seat's keyboard
// capability, Qt clients throw away their wl_keyboard, and a session-lock surface that stayed mapped never gets keyboard
// enter again, so its password field gets no keys after a wake. A virtual keyboard is not a libinput device: it stays,
// the capability stays, and focus is kept. This program never sends a key.
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <wayland-client.h>
#include <xkbcommon/xkbcommon.h>
#include "vk.h"

static struct wl_seat *seat;
static struct zwp_virtual_keyboard_manager_v1 *manager;

static void global(void *data, struct wl_registry *reg, uint32_t name, const char *iface, uint32_t version) {
    (void)data;
    (void)version;
    if (!seat && strcmp(iface, wl_seat_interface.name) == 0)
        seat = wl_registry_bind(reg, name, &wl_seat_interface, 1);
    else if (strcmp(iface, zwp_virtual_keyboard_manager_v1_interface.name) == 0)
        manager = wl_registry_bind(reg, name, &zwp_virtual_keyboard_manager_v1_interface, 1);
}
static void global_remove(void *data, struct wl_registry *reg, uint32_t name) { (void)data; (void)reg; (void)name; }
static const struct wl_registry_listener registry_listener = { global, global_remove };

int main(void) {
    struct wl_display *display = wl_display_connect(NULL);
    if (!display) { fprintf(stderr, "keep-keyboard: no Wayland display\n"); return 1; }
    struct wl_registry *reg = wl_display_get_registry(display);
    wl_registry_add_listener(reg, &registry_listener, NULL);
    wl_display_roundtrip(display);
    if (!seat || !manager) { fprintf(stderr, "keep-keyboard: compositor has no seat or virtual keyboard manager\n"); return 1; }

    // the same layout as the real keyboard, so a client that reads this keymap while it is the active one sees nothing odd
    struct xkb_context *ctx = xkb_context_new(XKB_CONTEXT_NO_FLAGS);
    struct xkb_rule_names names = { .layout = "us" };
    struct xkb_keymap *keymap = ctx ? xkb_keymap_new_from_names(ctx, &names, XKB_KEYMAP_COMPILE_NO_FLAGS) : NULL;
    char *text = keymap ? xkb_keymap_get_as_string(keymap, XKB_KEYMAP_FORMAT_TEXT_V1) : NULL;
    if (!text) { fprintf(stderr, "keep-keyboard: could not build a keymap\n"); return 1; }
    size_t size = strlen(text) + 1;
    int fd = memfd_create("keep-keyboard-keymap", MFD_CLOEXEC);
    if (fd < 0 || write(fd, text, size) != (ssize_t)size) { perror("keep-keyboard: keymap"); return 1; }

    struct zwp_virtual_keyboard_v1 *kb = zwp_virtual_keyboard_manager_v1_create_virtual_keyboard(manager, seat);
    zwp_virtual_keyboard_v1_keymap(kb, WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1, fd, size);
    wl_display_roundtrip(display);
    close(fd);
    free(text);
    fprintf(stderr, "keep-keyboard: virtual keyboard held\n");

    while (wl_display_dispatch(display) != -1) {}
    fprintf(stderr, "keep-keyboard: lost the compositor\n");
    return 1;
}
