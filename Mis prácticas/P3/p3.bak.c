/*
////////////////////////////////////////////////////////////////////////////////
//
// Francisco Javier Caracuel Beltrán
//
// Práctica 3 - Modelos de Computación
//
// Grado en Ingeniería Informática - Curso 2016/2017
//
////////////////////////////////////////////////////////////////////////////////
/*

/*
////////////////////////////////////////////////////////////////////////////////
// Sección de Declaraciones
//
*/

%{
    
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>
    
int numPrice;
double price;

#define nTrip 10
    
int iPrice;
int iName;
int iDate;
int iAge;

struct MemoryStruct {
  char *memory;
  size_t size;
};

struct Trip{
    char name[50];
    double price;
    double score;
    char date[50];
    int age;
};

struct Trip trip[nTrip];

static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp);

void setPrice();
void setName();
void setDate();
void setAge();

void showData(int numPrice, double price);

%}

/*
//
////////////////////////////////////////////////////////////////////////////////
*/

%%

(price)+     { ECHO;}
[\t]+       { price += yyleng;}
\n          {  }
.           {}

%%

int main (int argc, char *argv[]) {

    // Struct donde se guardará el código fuente de la página
    struct MemoryStruct chunk;

    // Reserva de memoria e inicialización de la longitud del código fuente
    chunk.memory = malloc(1);
    chunk.size = 0;

    // A través de CURL se obtiene el código fuente de blablacar
    CURL *curl;
    CURLcode res;

    curl = curl_easy_init();

    // Si no ha habido ningún error al iniciar curl
    if (curl) {

        // Se envía la url de la que se quiere obtener respuesta
        curl_easy_setopt(curl, CURLOPT_URL, "https://www.blablacar.es/coche-compartido/granada/sevilla/#?fn=Granada&tn=Sevilla&limit=100&page=1");

        // Se permite la redirección que tenga la url
        curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);

        // Función que se encargará de guardar el código fuente
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);

        // Se le envía la variable donde se va a escribir el código fuente
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);

        // Para que el servidor de la url detecte un agente de navegador
        curl_easy_setopt(curl, CURLOPT_USERAGENT, "libcurl-agent/1.0");

        // Se realiza la petición
        res = curl_easy_perform(curl);

        // Se detecta si ha habido errores
        if (res != CURLE_OK)
            fprintf(stderr, "curl_easy_perform() failed: %s\n",
                curl_easy_strerror(res));

        // Se limpia el objeto curl
        curl_easy_cleanup(curl);

        // Se le indica a lex el texto que debe escanear
        yy_scan_string(chunk.memory);

        // Se libera la memoria del objeto que tiene el código fuente
        free(chunk.memory);

        // Se vacía completamente el objeto curl
        curl_global_cleanup();

    }

    // Se inicializan las variables que contarán
    numPrice = price = 0;

    // Se inicia el escaneo del código fuente
    yylex();

    // Se muestran los resultados obtendidos
    showData(numPrice, price);
        
    return 0;

}

static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp){

    size_t realsize = size * nmemb;
    struct MemoryStruct *mem = (struct MemoryStruct *) userp;

    mem->memory = realloc(mem->memory, mem->size + realsize + 1);
    
    if (mem->memory == NULL) {
        /* out of memory! */
        printf("not enough memory (realloc returned NULL)\n");
        return 0;
    }

    memcpy(&(mem->memory[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->memory[mem->size] = 0;

    return realsize;

}

void setPrice(){
        
    double p = atof(&yytext[0]) + atof(&yytext[yyleng-2])/100;
            
    trip[iPrice].price = p;
    
    iPrice++;
        
}

void setName(){
    
    // Desde el principio hasta que empieza el nombre hay 92 caracteres.
    // El total de caracteres estáticos son 122.
    // La cadena ocupara el tamaño de yytext menos 122.
    char n[50];
    memcpy(n, &yytext[92], yyleng-122);
    n[yyleng-122] = '\0';
    
    strncpy(trip[iName].name, n, sizeof trip[iName].name - 1);
    
    iName++;
        
}

void setDate(){
    
    // Desde el principio hasta que empieza el nombre hay 91 caracteres.
    // El total de caracteres estáticos son 113.
    // La cadena ocupara el tamaño de yytext menos 113.
    char d[50];
    memcpy(d, &yytext[91], yyleng-113);
    d[yyleng-113] = '\0';
    
    strncpy(trip[iDate].date, d, sizeof trip[iDate].date - 1);
    
    iDate++;
    
}

void setAge(){
    
    /*<div class="ProfileCard-info">
                                                        29 años<br />*/
    
    
    // Desde el principio hasta que empieza el nombre hay 87 caracteres.
    // El total de caracteres estáticos son 98.
    // La cadena ocupara el tamaño de yytext menos 113.
    /*char d[50];
    memcpy(d, &yytext[91], yyleng-113);
    d[yyleng-113] = '\0';
    
    strncpy(trip[iDate].date, d, sizeof trip[iDate].date - 1);*/
    
    double a = atof(&yytext[0]) + atof(&yytext[yyleng-2])/100;
            
    trip[iAge].age = a;
    
    iAge++;
    
}

void showData(int numPrice, double price){
    
    printf ("Número de precios=%d\tPrecio medio=%f\n",numPrice, price/numPrice);

}