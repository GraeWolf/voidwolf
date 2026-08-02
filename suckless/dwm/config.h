/* voidwolf dwm config — Mod4 Omarchy-inspired keybinds
 *
 * PR6/PR6b + PR11 media + PR13b gaps/scratchpad/sticky/attachaside.
 * docs/keybindings.md mirrors this file. Lint: ./tests/keybind-lint.sh
 *
 * Policy locks:
 *   - MODKEY = Super (Mod4)
 *   - Super+K = cheatsheet only (never focus)
 *   - Super+L = focusdir right only (never layout)
 *   - Super+Shift+L = cyclelayout (not movestack)
 *   - Super+S = scratchpad; Super+O = sticky
 *
 * Fonts live here (not themed). Colors come from colors.h (theme-generated).
 */

#include <X11/XF86keysym.h>

/* appearance */
static const unsigned int borderpx  = 2;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
/* systray (in-bar tray icons) */
static const unsigned int systraypinning = 0;   /* 0: follows selected monitor, >0: pin to mon X */
static const unsigned int systrayonleft  = 0;   /* >0: tray left of status text */
static const unsigned int systrayspacing = 2;
static const int systraypinningfailfirst = 1;   /* 1: pin-fail → first monitor */
static const int showsystray        = 1;        /* 0 means no systray */
/* vanitygaps (PR13b) */
static const unsigned int gappih    = 8;        /* horiz inner gap between windows */
static const unsigned int gappiv    = 8;        /* vert inner gap between windows */
static const unsigned int gappoh    = 8;        /* horiz outer gap — edge */
static const unsigned int gappov    = 8;        /* vert outer gap — edge */
static       int smartgaps          = 0;        /* 1 = no outer gap when single window */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
/* Primary UI font + Nerd Font symbols for status2d bar icons (ChadWM-style) */
static const char *fonts[]          = {
	"Fira Code:size=11",
	"Symbols Nerd Font Mono:size=11",
	"Symbols Nerd Font:size=11",
	"DejaVu Sans Mono:size=11",
};
static const char dmenufont[]       = "Fira Code:size=11";

#include "colors.h"

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

/*
 * Per-monitor tag sets (Xinerama mon index = m->num).
 * Default dual-head desk: mon 0 = tags 1–6, mon 1 = tags 7–9.
 * If your HDMI-0/HDMI-1 order is swapped, reverse the two entries.
 * Bits: tag N uses bit (N-1).
 */
static const unsigned int mon_tagmask[] = {
	(1u << 0) | (1u << 1) | (1u << 2) | (1u << 3) | (1u << 4) | (1u << 5), /* mon0: 1-6 */
	(1u << 6) | (1u << 7) | (1u << 8),                                       /* mon1: 7-9 */
};

static const Rule rules[] = {
	/* class      instance    title       tags mask     isfloating   monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           -1 },
	{ "Firefox",  NULL,       NULL,       0,            0,           -1 },
	{ "Brave-browser", NULL,  NULL,       0,            0,           -1 },
	/* voidwolf TUI helpers (title starts with voidwolf-tui) — float + center */
	{ NULL,       NULL,       "voidwolf-tui", 0,         1,           -1 },
	/* btop launched via Super+Ctrl+T */
	{ NULL,       NULL,       "voidwolf-btop", 0,        1,           -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

#define FORCE_VSPLIT 1  /* nrowgrid: force two clients to split vertically */
#include "vanitygaps.c"

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "[M]",      monocle },
	{ "><>",      NULL },    /* floating */
	{ "[@]",      spiral },
	{ "[\\]",     dwindle },
	{ "TTT",      bstack },
	{ NULL,       NULL },    /* cyclelayout terminator */
};

/* key definitions */
#define MODKEY Mod4Mask
/* view/tag jump to the monitor that owns the tag (mon_tagmask) */
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      viewontagmon,         {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleviewontagmon,   {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tagontagmon,          {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,            {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont,
	"-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[]     = { "st", NULL };
static const char *browser[]     = { "voidwolf-browser", NULL };
static const char *launcher[]    = { "voidwolf-launcher", NULL };
static const char *vwmenu[]      = { "voidwolf-menu", NULL };
static const char *sysmenu[]     = { "voidwolf-system-menu", NULL };
static const char *lockcmd[]     = { "voidwolf-lock", NULL };
static const char *nvimcmd[]     = { "st", "-e", "nvim", NULL };
static const char *themecmd[]    = { "voidwolf-theme", "pick", NULL };
static const char *wallcmd[]     = { "voidwolf-wallpaper", "pick", NULL };
static const char *cheatcmd[]    = { "voidwolf-cheatsheet", NULL };
static const char *audiocmd[]    = { "voidwolf-audio-tui", NULL };
static const char *btcmd[]       = { "voidwolf-bluetooth-tui", NULL };
static const char *wificmd[]     = { "voidwolf-wifi-tui", NULL };
static const char *btopcmd[]     = { "st", "-t", "voidwolf-btop", "-g", "120x40", "-e", "btop", NULL };
static const char *dunstclose[]  = { "dunstctl", "close", NULL };
static const char *dunstcloseall[] = { "dunstctl", "close-all", NULL };
static const char *dunstpause[]  = { "dunstctl", "set-paused", "toggle", NULL };
static const char *dunsthist[]   = { "dunstctl", "history-pop", NULL };
static const char *scrotmenu[]   = { "voidwolf-screenshot", "menu", NULL };
static const char *scrotfull[]   = { "voidwolf-screenshot", "full", NULL };
static const char *scrotregion[] = { "voidwolf-screenshot", "region", NULL };
static const char *filemgr[]     = { "voidwolf-filemanager", NULL };
static const char *clipmenu[]    = { "voidwolf-clipboard", NULL };
/* PR11: media + backlight (desktop volume always; brightness no-ops if no sysfs) */
static const char *volup[]       = { "voidwolf-volume", "up", NULL };
static const char *voldown[]     = { "voidwolf-volume", "down", NULL };
static const char *volmute[]     = { "voidwolf-volume", "mute", NULL };
static const char *brightup[]    = { "voidwolf-brightness", "up", NULL };
static const char *brightdown[]  = { "voidwolf-brightness", "down", NULL };
/* PR13b scratchpad — floating st toggled with Super+S */
static const char scratchpadname[] = "scratchpad";
static const char *scratchpadcmd[] = { "st", "-t", scratchpadname, "-g", "120x34", NULL };

/* status bar clicks: BUTTON env set by statuscmd; id matches \\001, \\002, … in voidwolf-status */
static const StatusCmd statuscmds[] = {
	{ "voidwolf-status-click updates", 1 },
	{ "voidwolf-status-click volume", 2 },
};
static char *statuscmd[] = { "/bin/sh", "-c", NULL, NULL };

#include "movestack.c"
#include "shiftview.c"
#include "cyclelayout.c"

static const Key keys[] = {
	/* modifier                     key        function        argument */
	/* === PR6 CORE: launch === */
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY|ShiftMask,             XK_b,      spawn,          {.v = browser } }, /* Super+Shift+B → Brave */
	{ MODKEY,                       XK_space,  spawn,          {.v = launcher } },
	{ MODKEY|Mod1Mask,              XK_space,  spawn,          {.v = vwmenu } },
	{ MODKEY,                       XK_Escape, spawn,          {.v = sysmenu } },
	{ MODKEY|ControlMask,           XK_l,      spawn,          {.v = lockcmd } },
	{ MODKEY|ShiftMask,             XK_n,      spawn,          {.v = nvimcmd } },
	{ MODKEY|ControlMask|ShiftMask, XK_space,  spawn,          {.v = themecmd } },
	{ MODKEY|ControlMask,           XK_space,  spawn,          {.v = wallcmd } },
	{ MODKEY,                       XK_k,      spawn,          {.v = cheatcmd } },
	{ MODKEY|ControlMask,           XK_a,      spawn,          {.v = audiocmd } },
	{ MODKEY|ControlMask,           XK_b,      spawn,          {.v = btcmd } },
	{ MODKEY|ControlMask,           XK_w,      spawn,          {.v = wificmd } },
	{ MODKEY|ControlMask,           XK_t,      spawn,          {.v = btopcmd } },
	{ MODKEY|ShiftMask,             XK_f,      spawn,          {.v = filemgr } },

	/* === PR6b: notifications (Super+, is dunst — mon uses Super+period) === */
	{ MODKEY,                       XK_comma,  spawn,          {.v = dunstclose } },
	{ MODKEY|ShiftMask,             XK_comma,  spawn,          {.v = dunstcloseall } },
	{ MODKEY|ControlMask,           XK_comma,  spawn,          {.v = dunstpause } },
	{ MODKEY|Mod1Mask,              XK_comma,  spawn,          {.v = dunsthist } },

	/* === capture (no Print key required) === */
	/* Super+Shift+P full; Super+Shift+S region; Super+Ctrl+C menu */
	{ MODKEY|ShiftMask,             XK_p,      spawn,          {.v = scrotfull } },
	{ MODKEY|ShiftMask,             XK_s,      spawn,          {.v = scrotregion } },
	{ MODKEY|ControlMask,           XK_c,      spawn,          {.v = scrotmenu } },
	/* keep Print aliases when the key exists */
	{ 0,                            XK_Print,  spawn,          {.v = scrotfull } },
	{ ShiftMask,                    XK_Print,  spawn,          {.v = scrotregion } },
	{ MODKEY|ControlMask,           XK_v,      spawn,          {.v = clipmenu } },

	/* === PR11: XF86 media / brightness (no Super modifier) === */
	{ 0, XF86XK_AudioRaiseVolume,  spawn, {.v = volup } },
	{ 0, XF86XK_AudioLowerVolume,  spawn, {.v = voldown } },
	{ 0, XF86XK_AudioMute,         spawn, {.v = volmute } },
	{ 0, XF86XK_MonBrightnessUp,   spawn, {.v = brightup } },
	{ 0, XF86XK_MonBrightnessDown, spawn, {.v = brightdown } },

	/* client */
	{ MODKEY,                       XK_w,      killclient,     {0} },
	{ MODKEY,                       XK_t,      togglefloating, {0} },
	{ MODKEY,                       XK_f,      togglefullscr,  {0} },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglebar,      {0} }, /* Omarchy-like bar toggle */

	/* === PR13b: scratchpad, sticky, vanitygaps === */
	{ MODKEY,                       XK_s,      togglescratch,  {.v = scratchpadcmd } },
	{ MODKEY,                       XK_o,      togglesticky,   {0} },
	{ MODKEY,                       XK_g,      togglegaps,     {0} },
	{ MODKEY|ShiftMask,             XK_g,      defaultgaps,    {0} },
	{ MODKEY|ControlMask,           XK_equal,  incrgaps,       {.i = +2 } },
	{ MODKEY|ControlMask,           XK_minus,  incrgaps,       {.i = -2 } },

	/* focusdir: 0=left 1=right 2=up 3=down — Super+L is focus right ONLY */
	{ MODKEY,                       XK_h,      focusdir,       {.i = 0 } },
	{ MODKEY,                       XK_l,      focusdir,       {.i = 1 } },
	{ MODKEY,                       XK_j,      focusdir,       {.i = 3 } },
	{ MODKEY,                       XK_Left,   focusdir,       {.i = 0 } },
	{ MODKEY,                       XK_Right,  focusdir,       {.i = 1 } },
	{ MODKEY,                       XK_Up,     focusdir,       {.i = 2 } },
	{ MODKEY,                       XK_Down,   focusdir,       {.i = 3 } },

	/* Alt+Tab window cycle */
	{ Mod1Mask,                     XK_Tab,    focusstack,     {.i = +1 } },
	{ Mod1Mask|ShiftMask,           XK_Tab,    focusstack,     {.i = -1 } },

	/* movestack (not Super+Shift+L) */
	{ MODKEY|ShiftMask,             XK_h,      movestack,      {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_j,      movestack,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_Left,   movestack,      {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_Down,   movestack,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_Up,     movestack,      {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_Right,  movestack,      {.i = +1 } },

	/* layout: Super+Shift+L cycles layouts via cyclelayout */
	{ MODKEY|ShiftMask,             XK_l,      cyclelayout,    {.i = +1 } },
	{ MODKEY|ControlMask|ShiftMask, XK_l,      cyclelayout,    {.i = -1 } },
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY|ShiftMask,             XK_t,      setlayout,      {.v = &layouts[0]} },

	/* master / stack — Super+equal/minus setmfact */
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_equal,  setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_minus,  setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_z,      zoom,           {0} },

	/* === PR6b: tag cycle (Super+Tab) + former tags (Super+Ctrl+Tab) === */
	{ MODKEY,                       XK_Tab,    shiftview,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_Tab,    shiftview,      {.i = -1 } },
	{ MODKEY|ControlMask,           XK_Tab,    view,           {0} }, /* toggle last tagset */

	/* monitors — Super+period family (Super+comma is dunst) */
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	{ MODKEY|ControlMask,           XK_period, focusmon,       {.i = -1 } },
	{ MODKEY|ControlMask|ShiftMask, XK_period, tagmon,         {.i = -1 } },

	/* tags 1–9 */
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },

	/* quit / restart (restartsig) */
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
	{ MODKEY|ControlMask|ShiftMask, XK_q,      quit,           {1} },
};

/* button definitions */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	/* statuscmd: Button1 click, Button4/5 scroll (volume), etc. */
	{ ClkStatusText,        0,              Button1,        spawn,          {.v = statuscmd } },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = statuscmd } },
	{ ClkStatusText,        0,              Button3,        spawn,          {.v = statuscmd } },
	{ ClkStatusText,        0,              Button4,        spawn,          {.v = statuscmd } },
	{ ClkStatusText,        0,              Button5,        spawn,          {.v = statuscmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
