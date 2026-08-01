/* colors.h — default palette for voidwolf dwm
 *
 * GENERATED / owned by voidwolf-theme (PR8+). Do not hand-edit for daily theming;
 * re-running the theme engine overwrites this file.
 * Safe defaults ship here so PR4 builds work before the theme engine exists.
 */
static const char col_gray1[]       = "#1d2021"; /* bg */
static const char col_gray2[]       = "#3c3836"; /* border unfocused */
static const char col_gray3[]       = "#ebdbb2"; /* fg */
static const char col_gray4[]       = "#1d2021"; /* sel fg */
static const char col_cyan[]        = "#458588"; /* accent / sel bg / border */
static const char col_urgborder[]   = "#cc241d"; /* unused unless urgent patch */

static const char *colors[][3] = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};
