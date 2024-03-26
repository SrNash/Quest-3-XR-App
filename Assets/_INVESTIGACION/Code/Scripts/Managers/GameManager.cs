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
	/// GameManager, controlará o bien la escena o bien el juego
	/// </summary>

	public class GameManager : MonoBehaviour
	{
		#region Enums
		#endregion
		#region Static Fields
		private static GameManager instance;
		public static GameManager Instance { get { return instance; } }
		#endregion
		#region Private Fields
		[SerializeField] private int targetFrameRate;
		[SerializeField] private string sceneName;
		[SerializeField] private string nextSceneName;
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
			Application.targetFrameRate = targetFrameRate;
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
			if (sceneName != nextSceneName)
			{
				if (instance == null)
				{
					instance = this;
				}
				else
				{
					DontDestroyOnLoad(gameObject);
				}
			}
			else if (sceneName == nextSceneName)
			{
				Destroy(this.gameObject);
			}
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