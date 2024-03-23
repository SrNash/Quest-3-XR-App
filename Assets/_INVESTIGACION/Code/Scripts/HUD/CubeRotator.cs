/*-----------------------------
 -------------------------------
 Creation Date: #CREATIONDATE#
 Author: #DEVELOPER#
 Description: #PROJECTNAME#
--------------------------------
-----------------------------*/

using JetBrains.Annotations;
using Oculus.Interaction.Editor;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Dev.Bakata{

	/// <summary>
	/// 
	/// </summary>

	public class CubeRotator : MonoBehaviour, IRotatable
	{
		#region Static Fields
		#endregion
		#region Const Field
		#endregion
		#region Param Fields
		#endregion
		#region Private Fields
		[Tooltip("Reference to the Cube GameObject that rotate arouns delf.")]
		[SerializeField] private GameObject cubeGO;
		[SerializeField] private float rotationSpeed;
		private float smoothSpeed = 0.0125f;
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
			RotateAroundSelf();
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
        public void RotateAroundSelf()
        {
			float rotationSmoothedSpeed = rotationSpeed * smoothSpeed;
			cubeGO.transform.RotateAround(Vector3.up,rotationSmoothedSpeed);
        }
        #endregion
    }
}