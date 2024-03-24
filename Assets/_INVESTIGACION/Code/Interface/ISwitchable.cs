/*-----------------------------
 -------------------------------
 Creation Date: 24/03/24
 Author: victo
 Description: Quest 3 XR App
--------------------------------
-----------------------------*/

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Dev.Bakata
{

    /// <summary>
    /// 
    /// </summary>

    public interface ISwitchable
    {
        #region Private Fields

        #endregion
        #region Public Fields
        public bool IsActive { get; set; }
        public bool IsLocked { get; set; }
        public bool IsUnlocked { get; set; }
        #endregion
        #region Private Methods

        #endregion
        #region Public Methods
        public void Unlocked();
        public void Activate();
        public void Desactivate();
        #endregion



    }
}