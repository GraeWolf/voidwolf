/* cyclelayout — walk layouts[] forward/back (PR6b Super+Shift+L)
 * Included from config.h. Does not touch Super+L (focusdir right).
 */
void
cyclelayout(const Arg *arg)
{
	Layout *l;
	for (l = (Layout *)layouts; l != selmon->lt[selmon->sellt]; l++)
		;
	if (arg->i > 0) {
		if (l->symbol && (l + 1)->symbol)
			setlayout(&((Arg){ .v = (l + 1) }));
		else
			setlayout(&((Arg){ .v = layouts }));
	} else {
		Layout *p = (Layout *)layouts;
		if (l == layouts)
			/* go to last defined layout */
			while ((p + 1)->symbol)
				p++;
		else
			p = l - 1;
		setlayout(&((Arg){ .v = p }));
	}
}
