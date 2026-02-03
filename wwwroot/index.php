<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Demostración de CSS: Float, Flexbox y Grid</title>
    <link rel="stylesheet" href="css/style.css">
</head>

<body>

    <header class="header">
        <h1>Demostración de CSS PHP <?php echo " Hola Mundo!" ?></h1>
        <p>Float • Flexbox • Grid</p>
    </header>

    <!-- SECCIÓN FLOAT -->
    <section class="section-float">
        <h2>Ejemplo con Float</h2>
        <div class="float-container">
            <img src="https://picsum.photos/200" alt="Imagen ejemplo">
            <p>
                Esta sección utiliza <strong>float</strong> para colocar la imagen a la izquierda y permitir que el texto fluya a su alrededor.
                Aunque float se usaba antiguamente para maquetación, hoy se reserva para efectos como este.
            </p>
        </div>
    </section>

    <!-- SECCIÓN FLEXBOX -->
    <section class="section-flex">
        <h2>Ejemplo con Flexbox</h2>
        <p>Flexbox permite distribuir elementos de forma flexible y adaptable.</p>

        <div class="flex-container">
            <div class="flex-item">Elemento 1</div>
            <div class="flex-item">Elemento 2</div>
            <div class="flex-item">Elemento 3</div>
        </div>
    </section>

    <!-- SECCIÓN GRID -->
    <section class="section-grid">
        <h2>Ejemplo con CSS Grid</h2>
        <p>Grid permite crear estructuras bidimensionales muy potentes.</p>

        <div class="grid-container">
            <div class="grid-item">A</div>
            <div class="grid-item">B</div>
            <div class="grid-item">C</div>
            <div class="grid-item">D</div>
            <div class="grid-item">E</div>
            <div class="grid-item">F</div>
        </div>
    </section>

    <footer class="footer">
        <p>Creado para demostrar técnicas modernas y clásicas de CSS.</p>
    </footer>

</body>

</html>