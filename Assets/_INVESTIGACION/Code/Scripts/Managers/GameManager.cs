/*-----------------------------
 -------------------------------
 Creation Date: #CREATIONDATE#
 Author: #DEVELOPER#
 Description: #PROJECTNAME#
--------------------------------
-----------------------------*/

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace Dev.Bakata{

	/// <summary>
	/// 
	/// </summary>

	public class GameManager : MonoBehaviour
	{
		#region Enums
		#endregion
		#region Static Fields
		#endregion
		#region Private Fields
		#endregion
		#region Public Fields
        #endregion
        #region Lifecycle
        #endregion
        #region Public API
        #endregion
        #region Unity Methods
        // Start is called before the first frame update
        void Start()
		{
			
		}

		// Update is called once per frame
		void Update()
		{
			
		}

		// Awake is called when the script is
		// first loaded or when an object is
		// attached to is instantiated
		void Awake()
		{
			
		}
	    
		// FixedUpdate is called at fixed time intervals
		void FixedUpdate()
		{
			
		}
            
		// LateUpdate is called after all Update functions have been called
		#endregion
		#region Private Methods
		#endregion            
		#region Public Methods
		public void LoadSceneOnClick(string sceneStr)
		{
            SceneManager.LoadScene(sceneStr);
        }
		#endregion
	}
}