/* shiftview — cycle visible tags left/right (PR6b Super+Tab)
 * Circular shift of the current tagset. Included from config.h.
 */
void
shiftview(const Arg *arg)
{
	Arg a = { .ui = 0 };
	int i = arg->i;
	unsigned int ts = selmon->tagset[selmon->seltags];
	int n = (int)LENGTH(tags);

	if (i > 0) /* next tags */
		a.ui = (ts << i) | (ts >> (n - i));
	else if (i < 0) {
		i = -i;
		a.ui = (ts >> i) | (ts << (n - i));
	} else
		return;
	/* mask to valid tags */
	a.ui &= TAGMASK;
	if (a.ui)
		view(&a);
}
