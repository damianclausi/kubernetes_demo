Prueba de Kubernetes: Escalado Horizontal y Autoreparación
Este documento describe los pasos para probar dos características clave de Kubernetes usando Minikube:

Escalado Horizontal: Aumentar el número de instancias (Pods) de una aplicación.

Autoreparación (Self-Healing): Ver cómo Kubernetes reemplaza automáticamente una instancia que falla.

Prerrequisitos
Un clúster de Minikube en funcionamiento.

Un Deployment llamado seminario-php creado a partir de un archivo deploy-seminario-php.yaml.

Una imagen Docker (seminario-php:latest) cargada en Minikube (minikube image load ...).

Un Service exponiendo el deployment (creado con kubectl expose ...).

Prueba 1: Escalado Horizontal (De 1 a 3 Réplicas)
El objetivo es decirle a Kubernetes que queremos 3 copias de nuestra aplicación corriendo en paralelo.

1. Modificar el Archivo de Deployment
Abre tu archivo deploy-seminario-php.yaml y cambia el valor de replicas de 1 a 3.

YAML

apiVersion: apps/v1
kind: Deployment
metadata:
  name: seminario-php
spec:
  replicas: 3  # <-- ASEGÚRATE QUE ESTE VALOR SEA 3
  selector:
    matchLabels:
      app: seminario-php
  template:
    metadata:
      labels:
        app: seminario-php
    spec:
      containers:
      - image: seminario-php:latest
        name: seminario-php
        imagePullPolicy: IfNotPresent
2. Aplicar los Cambios
Guarda el archivo y aplica la nueva configuración al clúster:

Bash

kubectl apply -f deploy-seminario-php.yaml
3. Observar el Escalado
Usa el comando watch (-w) para ver en tiempo real cómo Kubernetes crea los nuevos Pods para cumplir con el estado deseado de 3 réplicas.

Bash

kubectl get pods -w
Salida esperada: Verás tu Pod original y dos nuevos Pods pasando por los estados Pending -> ContainerCreating -> Running.

NAME                             READY   STATUS              RESTARTS   AGE
seminario-php-5b5f68cbbb-ncfgf   1/1     Running             0          10m
seminario-php-5b5f68cbbb-abc12   0/1     Pending             0          2s
seminario-php-5b5f68cbbb-xyz78   0/1     Pending             0          2s
seminario-php-5b5f68cbbb-abc12   0/1     ContainerCreating   0          3s
seminario-php-5b5f68cbbb-xyz78   0/1     ContainerCreating   0          3s
seminario-php-5b5f68cbbb-abc12   1/1     Running             0          10s
seminario-php-5b5f68cbbb-xyz78   1/1     Running             0          10s
Presiona Ctrl+C para salir. Ahora tienes 3 instancias de tu aplicación.

Prueba 2: Autoreparación (Simulación de Caos)
El objetivo es simular un fallo (borrando un Pod) y ver cómo el Deployment lo reemplaza automáticamente para mantener siempre 3 instancias.

1. Listar los Pods
Primero, obtén los nombres completos de tus 3 Pods en ejecución:

Bash

kubectl get pods
Salida esperada:

NAME                             READY   STATUS    RESTARTS   AGE
seminario-php-5b5f68cbbb-ncfgf   1/1     Running   0          12m
seminario-php-5b5f68cbbb-abc12   1/1     Running   0          2m
seminario-php-5b5f68cbbb-xyz78   1/1     Running   0          2m
2. Borrar un Pod Manualmente
Elige uno de los Pods y bórralo. Esto simula una caída inesperada del servidor.

Bash

# Reemplaza el nombre con uno de tu lista
kubectl delete pod seminario-php-5b5f68cbbb-abc12
3. Observar la Autoreparación
Inmediatamente después de borrar el Pod, vuelve a ejecutar el comando watch.

Bash

kubectl get pods -w
Salida esperada: Verás un evento fascinante: el Pod que borraste entra en estado Terminating (apagándose), y casi al mismo tiempo, un nuevo Pod (con un nombre diferente) entra en Pending y luego Running para reemplazarlo.

NAME                             READY   STATUS        RESTARTS   AGE
seminario-php-5b5f68cbbb-ncfgf   1/1     Running       0          13m
seminario-php-5b5f68cbbb-abc12   1/1     Terminating   0          3m  <-- El Pod borrado
seminario-php-5b5f68cbbb-xyz78   1/1     Running       0          3m
seminario-php-5b5f68cbbb-jkl45   0/1     Pending       0          1s  <-- El nuevo Pod de reemplazo
seminario-php-5b5f68cbbb-jkl45   0/1     ContainerCreating 0      2s
seminario-php-5b5f68cbbb-abc12   0/0     Terminating   0          3m5s
seminario-php-5b5f68cbbb-jkl45   1/1     Running       0          8s  <-- ¡Recuperado!
Conclusión: Has demostrado que Kubernetes mantiene activamente el estado deseado. Si un Pod muere, es reemplazado sin intervención manual.

(Opcional) Prueba 3: Resiliencia del Servicio (Cero Caídas)
Esta prueba demuestra que el Service (Balanceador de Carga) es lo suficientemente inteligente como para dirigir el tráfico solo a Pods saludables, resultando en cero tiempo de inactividad para el usuario.

Necesitarás 2 terminales.

Terminal 1: El Cliente
Obtén la URL de tu servicio:

Bash

minikube service seminario-php --url
(Ej: http://192.168.49.2:30573)

Ejecuta un bucle while en PowerShell que haga peticiones a esa URL cada medio segundo:

PowerShell

# Reemplaza la URL con la tuya
while (1) { curl http://192.168.49.2:30573; Start-Sleep -Milliseconds 500 }
Verás una lluvia constante de respuestas de tu aplicación.

Terminal 2: El Agente del Caos
Mientras el bucle se ejecuta en la Terminal 1, lista tus Pods:

Bash

kubectl get pods
Borra uno de los Pods (como en la Prueba 2):

Bash

kubectl delete pod [nombre-del-pod-a-borrar]
Resultado Esperado
Observa la Terminal 1 (el cliente). El bucle de curl no debería detenerse ni mostrar errores.
