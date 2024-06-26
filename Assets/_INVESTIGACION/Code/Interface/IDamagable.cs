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

	public interface IDamagable 
	{
        #region Private Fields
        #endregion
        #region Public Fields
        public bool WasHitted { get; set; }
        #endregion
        #region Private Methods
        #endregion
        #region Public Methods
        public void TakeDamage();
		public void Dead();
        #endregion
    }
	
}