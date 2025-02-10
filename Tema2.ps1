#Tema 2
#Ilustracion 13
#if(<test1>)
    #{<statement list 1>}
#[elseif (<test2>)
    #{<statement list 2>}]
#[elseif...]
#[else 
   # {<statement list 3>}]

#Ilustracion 14
$condicion = $true
if( $condicion )
{
    Write-Output "La condicion era verdadera"
}
else
{
    Write-Output "La condicion era falsa"
}

#ilustracion 15
$numero = 2
if( $numero -ge 3)
{
    Write-Output "El numero [$numero] es mayor que 3"
}
elseif ($numero -lt 2) {
    Write-Output "El numero [$numero] es menor que 2"
}
else {
    Write-Output "El numero [$numero] es igual a 2"
}

#ilustracion 16
#<condicion> ? <if-true> : <if-false>

#ilustracion 17
$PSVersionTable

#ilustracion 18
#$mensaje = (Test-Path $path) ? "Path existe" : "Path no encontrado"

#ilustracion 19
switch (<test-expression>) {
    <result1-to-be-matched> { <action> }
    <result2-to-be-matched> { <action> }

}
if(<result1-to-be-matched> -eq (<test-expression>)) {<action>}
if(<result2-to-be-matched> -eq (<test-expression>)) {<action>}

#ilustracion 20


#ilustracion 21
switch (3) {
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres."}
    4 {"[$_] es cuatro."}
}

#ilustracion 22
switch (3) {
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres."}
    4 {"[$_] es cuatro."}
    3 {"[$_] tres de nuevo."}
}

#ilustracion 23
switch (3) {
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres.";break}
    4 {"[$_] es cuatro."}
    3 {"[$_] res de nuevo."}
}

#ilustracion 24
switch (1, 5) {
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres."}
    4 {"[$_] es cuatro."}
    5 {"[$_] es cinco."}
}

#ilustracion 25
switch ("seis") {
    1 {"[$_] es uno.";Break}
    2 {"[$_] es dos.";Break}
    3 {"[$_] es tres.";Break}
    4 {"[$_] es cuatro.";Break}
    5 {"[$_] es cinco.";Break}
    "se*"{"[$_] coincide con se*."}
    Default{
        "No hay coincidencias con [$_]"
    }
}

#ilustracion 26
switch -Wildcard ("seis") {
    1 {"[$_] es uno.";Break}
    2 {"[$_] es dos.";Break}
    3 {"[$_] es tres.";Break}
    4 {"[$_] es cuatro.";Break}
    5 {"[$_] es cinco.";Break}
    "se*"{"[$_] coincide con se*."}
    Default{
        "No hay coincidencias con [$_]"
    }
}

#ilustracion 27
$email = 'antonio.yanez@udc.es'
$email2 = 'antonio.yanez@usc.gal'
$url = 'https://www.dc.fi.udc.es/~afyanez/Docencia/2023'
switch -Regex ($url, $email, $email2) {
    {  
        '^\w+\.-?\w+@(udc|usc|edu)\.es|gal$' { "[$_] es una direccion de correo electronico academica" }  
        '^ftp://.*$' { "[$_] es una direccion ftp" }  
        '^(http[s]?)://.*$' { "[$_] es una direccion web, que utiliza [${matches[1]}]" }  
    }
}

#ilustracion 28
