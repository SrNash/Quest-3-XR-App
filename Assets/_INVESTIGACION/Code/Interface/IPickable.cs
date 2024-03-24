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
	/// Interface
	/// </summary>

	public interface IPickable
	{
        #region Private Field
        #endregion
        #region Public Fields
        public bool InReach { get; set; }
        #endregion
        #region Private Methods
        #endregion
        #region Public Methods
        public void PickUp();
		public void DropItem();
        #endregion
    }
}