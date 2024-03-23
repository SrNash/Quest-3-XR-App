/*-----------------------------
 -------------------------------
 Creation Date: 23/03/24
 Author: Victor
 Description: Quest 3 XR App
--------------------------------
-----------------------------*/

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Dev.Bakata{

	/// <summary>
	/// 
	/// </summary>

	public class Switch : MonoBehaviour
	{
		#region Public Fields
		public ISwitchable client;
		#endregion
		#region Public Methods
		public void Toggle()
		{
			if (client.IsActive)
			{
				client.Desactivate();
			}
			else if(client.IsLocked)
			{
				client.Unlocked();
			}else if(client.IsUnlocked)
			{
				client.Activate();
			}
			else
			{
				client.Activate();
			}
		}
		#endregion
	}
}