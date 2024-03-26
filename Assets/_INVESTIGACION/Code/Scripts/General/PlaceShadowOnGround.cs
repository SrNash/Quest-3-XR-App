/*-----------------------------
 -------------------------------
 Creation Date: 26/03/24
 Author: victo
 Description: Quest 3 XR App
--------------------------------
-----------------------------*/

using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using Unity.VisualScripting.Antlr3.Runtime.Collections;
using UnityEditor.PackageManager;
using UnityEngine;

namespace Dev.Bakata{

	/// <summary>
	/// Este script es el encargado de ubicar la sombra del GameObject al que va asignado
	/// en la posición de este pero a la altura deseada (suelo).
	/// </summary>

	public class PlaceShadowOnGround : MonoBehaviour
	{
		#region Private Fields
		[SerializeField] private Transform shadowTransform;
		[SerializeField] private Transform target;
		[SerializeField] private float raycastDistance = 5.0f;
		[SerializeField] private LayerMask layerMask;
		[SerializeField] private float radius = 0.04f;
		private float maxRadius = 0.04f;
		private float minRadius = 0.0125f;
		private float radiusDecreaseFactor = 0.1f;
		[SerializeField] private float verticalOffset = 0.00125f;
		private Vector3 direction = Vector3.down;
        #endregion
        #region Public Fields
        #endregion
        #region Unity Methods
        // Start is called before the first frame update
        void Start()
		{
			
		}

		// Update is called once per frame
		void Update()
		{
			//Raycast
			RaycastHit raycastHit;

			//Booleana local para comprobar si detecta suelo
			bool hasHit = Physics.SphereCast(transform.position, radius, direction, out raycastHit, raycastDistance, layerMask);

			//Si detecta suelo
			if (hasHit)
			{
				// Ajustar el radio en función de la distancia al suelo
				float adjustedRadius = Mathf.Clamp(radius - raycastHit.distance * radiusDecreaseFactor, minRadius, maxRadius);

				// Posicionar la sombra a la altura del suelo
				shadowTransform.position = new Vector3(transform.position.x, raycastHit.point.y + verticalOffset, transform.position.z);

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

		void OnDrawGizmos()
		{
            //Raycast
            RaycastHit raycastHit;

            //Booleana local para comprobar si detecta suelo
            bool hasHit = Physics.SphereCast(transform.position, radius, direction, out raycastHit, raycastDistance, layerMask);

            //Si detecta suelo
            if (hasHit)
            {
                // Ajustar el radio en función de la distancia al suelo
                float adjustedRadius = Mathf.Clamp(radius - raycastHit.distance * radiusDecreaseFactor, minRadius, maxRadius);

                // Posicionar la sombra a la altura del suelo
                shadowTransform.position = new Vector3(transform.position.x, raycastHit.point.y + verticalOffset, transform.position.z);

                // Dibujar el SphereCast con el radio ajustado
                Gizmos.color = Color.blue;
                Gizmos.DrawWireSphere(transform.position, adjustedRadius);
            }
        }
	}
}