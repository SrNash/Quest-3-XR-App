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
	/// Se encarga de spawnear las esferas que seran llamadas cuando el usuario "dispare"
	/// </summary>

	public class SpawnBall : MonoBehaviour
	{
		#region Static Fields
		#endregion
		#region Const Field
		#endregion
		#region Param Fields
		#endregion
		#region Private Fields
		#endregion
		#region Public Fields
		public BallsObjectPool ballsPool;
		#endregion
		#region Lifecycle
		#endregion
		#region Public API
		#endregion
		#region Unity Methods
		// Start is called before the first frame update
		void Start()
		{
			ballsPool.InitPool();
		}

		// Update is called once per frame
		void Update()
		{
			if (OVRInput.GetDown(OVRInput.Button.SecondaryIndexTrigger))
			{
				ballsPool.force = 2.5f;
				ballsPool.ShootBall(transform.position);
			}
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
		#endregion
	}
}