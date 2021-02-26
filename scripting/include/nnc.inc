#if defined _nnc_included
	#endinput
#endif

#define _nnc_included

#include <nnc_const>

/**
 * Called when a player attemtps to change his name
 *
 * @param id            Client index
 * @param oldname       Old name
 * @param newname       New name
 * @return              NNC_CONTINUE not to change the behavior
 *                      NNC_BLOCK to block the name change
 *                      NNC_ALLOW to allow the name change, ignoring all other checks
 */
forward nnc_user_name_changed(id, oldname[], newname[])

/**
 * Changes a player's name, bypassing the plugin's protection.
 *
 * @param id            Client index
 * @param name          Name to set
 * @param showmsg       If set to false, the name change message won't display in chat
 * @noreturn
 */
native nnc_change_user_name(id, const name[], bool:showmsg = true)

/**
 * Returns how many times players can change their name.
 *
 * @return              Number of maximum allowed name changes
 */
native nnc_get_max_changes()

/**
 * Returns how many times has the player changed his name.
 *
 * @param id            Client index
 * @return              Number of name changes
 */
native nnc_get_user_changes(id)

/**
 * Sets the amount of times the player has changed his name.
 *
 * @param id            Client index
 * @param num           Amount of name changes to set
 * @noreturn
 */
native nnc_set_user_changes(id, num)

/**
 * Returns how many more times can the player change his name.
 *
 * @param id            Client index
 * @return              Number of changes left
 */
native nnc_get_user_changes_left(id)