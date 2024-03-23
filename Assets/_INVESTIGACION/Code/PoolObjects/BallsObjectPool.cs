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
using UnityEngine.Pool;

namespace Dev.Bakata{

	/// <summary>
	/// ObjectPool de las esferas "disparadas" por el jugador
	/// </summary>

	public class BallsObjectPool : MonoBehaviour
	{
		#region Enums
		#endregion
		#region Static Fields
		private static BallsObjectPool instance;
		public static BallsObjectPool Instance { get { return instance; } }
		#endregion
		#region Const Field
		#endregion
		#region Param Fields
		#endregion
		#region Private Fields
		[SerializeField] private List<GameObject> ballsPooled;  // Lista para almacenar las balls
		private Coroutine returnToPool;	//Coroutina para el retorno de las balls al ObjectPool
		#endregion
		#region Public Fields
		public GameObject ballPrefab;	//Prefab de la Ball
		public int poolSize = 24;   // Tamaño de la ObjectPool
		public float force;
		public float timeToReturn = 5.0f;	//Tiempo de retorno al ObjectPool

        #endregion
        #region Unity Methods
        // Start is called before the first frame update
        void Start()
		{
			InitPool();
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
			if (instance == null)
			{
				instance = this;
			}
			else
			{
				Destroy(this.gameObject);
			}

			DontDestroyOnLoad(this.gameObject);
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
        public void InitPool()
        {
            //Inicializar la ObjectPool
            ballsPooled = new List<GameObject>();
            for (int i = 0; i < poolSize; i++)
            {
                GameObject ball = Instantiate(ballPrefab, transform);
                ball.SetActive(false);
                ballsPooled.Add(ball);
            }
        }
        //Metodo para obtener una Ball del ObjectPool
        public GameObject GetBall()
		{
			foreach (GameObject ball in ballsPooled)
			{
				if (!ball.activeInHierarchy)
				{
					return ball;
				}
			}
			return null;
		}

		//Metodo para activar una Ball en una posicion especifica
		public void ShootBall(Vector3 shootPosition)
		{
			GameObject ball = GetBall();
			if (ball != null)
			{
				ball.transform.position = shootPosition;
				ball.SetActive(true);

				Rigidbody rb = ball.GetComponent<Rigidbody>();
				if (rb != null)
				{
					//Aplicamos una fuerza hacia adelante al proyectil
					rb.AddForce(ball.transform.forward * force, ForceMode.Impulse);
				}

				//Iniciar la Coroutina para retornar la Ball a la posicion de ObjectPool
				//después de un determinado tiempo
				if (returnToPool != null)
				{
					StopCoroutine(returnToPool);
				}
				returnToPool = StartCoroutine(ReturnBall(ball));
			}
		}
        #endregion
        #region IEnumerator
		IEnumerator ReturnBall(GameObject ball)
		{
			yield return new WaitForSeconds(timeToReturn);
			ball.SetActive(false);
			ball.transform.position = transform.position;
		}
        #endregion
    }
}