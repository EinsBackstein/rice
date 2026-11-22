"""Nautilus right-click actions: Open in Ghostty, Copy path."""
import os
from urllib.parse import unquote, urlparse

import gi

gi.require_version("Nautilus", "4.1")
gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import GObject, Gdk, Gio, GLib, Nautilus


def _path(f):
    if f is None or f.get_uri_scheme() != "file":
        return None
    return unquote(urlparse(f.get_uri()).path)


class GhosttyMenu(GObject.GObject, Nautilus.MenuProvider):
    def _open(self, _item, path):
        d = path if os.path.isdir(path) else os.path.dirname(path)
        Gio.Subprocess.new(["ghostty", f"--working-directory={d}"], Gio.SubprocessFlags.NONE)

    def _copy(self, _item, path):
        display = Gdk.Display.get_default()
        if display:
            display.get_clipboard().set(path)

    def _items(self, path, key):
        o = Nautilus.MenuItem(name=f"Rice::OpenGhostty::{key}", label="Open in Ghostty")
        o.connect("activate", self._open, path)
        c = Nautilus.MenuItem(name=f"Rice::CopyPath::{key}", label="Copy path")
        c.connect("activate", self._copy, path)
        return [o, c]

    def get_file_items(self, *args):
        files = args[-1]
        if len(files) != 1:
            return []
        p = _path(files[0])
        return self._items(p, "file") if p else []

    def get_background_items(self, *args):
        p = _path(args[-1])
        return self._items(p, "bg") if p else []
