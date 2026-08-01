/* voidwolf dwm config — Mod4 Omarchy-inspired binds (Phase 1 core + PR4 patches)
 * Fonts live here (not themed). Colors come from colors.h (theme-generated).
 */

/* appearance */
static const unsigned int borderpx  = 2;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { "Fira Code:size=11", "DejaVu Sans Mono:size=11" };
static const char dmenufont[]       = "Fira Code:size=11";

#include "colors.h"

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* class      instance    title       tags mask     isfloating   monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           -1 },
	{ "Firefox",  NULL,       NULL,       0,            0,           -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

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
static const char *btopcmd[]     = { "st", "-e", "btop", NULL };
static const char *dunstclose[]  = { "dunstctl", "close", NULL };
static const char *dunstcloseall[] = { "dunstctl", "close-all", NULL };

#include "movestack.c"

static const Key keys[] = {
	/* modifier                     key        function        argument */
	/* launch */
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY|ShiftMask,             XK_Return, spawn,          {.v = browser } },
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
	{ MODKEY,                       XK_comma,  spawn,          {.v = dunstclose } },
	{ MODKEY|ShiftMask,             XK_comma,  spawn,          {.v = dunstcloseall } },

	/* client */
	{ MODKEY,                       XK_w,      killclient,     {0} },
	{ MODKEY,                       XK_t,      togglefloating, {0} },
	{ MODKEY,                       XK_f,      togglefullscr,  {0} },
	{ MODKEY,                       XK_b,      togglebar,      {0} },

	/* focusdir: 0=left 1=right 2=up 3=down — Super+L is focus right ONLY */
	{ MODKEY,                       XK_h,      focusdir,       {.i = 0 } },
	{ MODKEY,                       XK_l,      focusdir,       {.i = 1 } },
	{ MODKEY,                       XK_j,      focusdir,       {.i = 3 } },
	{ MODKEY,                       XK_Left,   focusdir,       {.i = 0 } },
	{ MODKEY,                       XK_Right,  focusdir,       {.i = 1 } },
	{ MODKEY,                       XK_Up,     focusdir,       {.i = 2 } },
	{ MODKEY,                       XK_Down,   focusdir,       {.i = 3 } },

	/* movestack (not Super+Shift+L — that is layout) */
	{ MODKEY|ShiftMask,             XK_h,      movestack,      {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_j,      movestack,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_Left,   movestack,      {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_Down,   movestack,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_Up,     movestack,      {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_Right,  movestack,      {.i = +1 } },

	/* layout: Super+Shift+L toggles previous layout (stock setlayout NULL) */
	{ MODKEY|ShiftMask,             XK_l,      setlayout,      {0} },
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY|ShiftMask,             XK_t,      setlayout,      {.v = &layouts[0]} },

	/* master / stack */
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_equal,  setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_minus,  setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_Tab,    view,           {0} },

	/* monitors */
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },

	/* tags */
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
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
