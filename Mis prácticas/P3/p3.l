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
    
#define nTrip 10
    
int iPrice;
int iName;
int iDate;
int iAge;
int iScore;
int iRatings;

typedef int (*compfn)(const void*, const void*);

struct MemoryStruct {
  char *memory;
  size_t size;
};

struct Trip{    
    char name[50];
    double price;
    double score;
    int ratings;
    char date[50];
    int age;    
};

struct Trip trip[nTrip];

static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp);

void setPrice();
void setName();
void setDate();
void setAge();
void setScore();
void setRatings();

int compare (struct Trip *a, struct Trip *b);
void showData();

%}

all         .*
enter       \n{all}
digit       [0-9]
price1      {digit}{1,2}
price2      {digit}{2}
price3      "<span class=\"size20\">,"
price       ({price1}{price3}{price2})
name1        "<h2 class=\"ProfileCard-info ProfileCard-info--name u-truncate\">"
name2       "</h2>"
name        ({name1}{enter}{2}{name2})
date1       "<h3 class=\"time light-gray\" itemprop=\"startDate\" content=\""[0-9]{4}-[0-9]{2}-[0-9]{2}"\">"
date2       "</h3>"
date        ({date1}{enter}{2}{date2})
age1        "<div class=\"ProfileCard-info\">"
age2        " años<br />"
age         ({age1}{enter}{age2})
score1      "<span class=\"u-textBold u-darkGray\">"
score2      "/"{digit}{1}
score       ({score1}{all}{score2})
ratings1    "<span class=\"u-gray\"> - "
ratings     ({ratings1}{digit}+)

/*
//
////////////////////////////////////////////////////////////////////////////////
*/

%%

{price}     {setPrice();}
{name}      {setName();}
{date}      {setDate();}
{age}       {setAge();}
{score}     {setScore();}
{ratings}   {setRatings();}
\n          {}
.           {}

%%

int main (int argc, char *argv[]) {

    if(argc != 3){
        printf("\nDebes introducir la ciudad de salida y de destino.\nUso: "
                "%s salida destino\n\n", &argv[0][0]);
        return -1;
    }
    
    char start[50], end[50];
    
    memcpy(start, &argv[1][0], 50);
    start[50] = '\0';
    
    memcpy(end, &argv[2][0], 50);
    end[50] = '\0';
        
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
        
        char url[500] = "https://www.blablacar.es/coche-compartido/";
        
        strcat(url, &start[0]);
        strcat(url, "/");
        strcat(url, &end[0]);
        strcat(url, "/");

        // Se envía la url de la que se quiere obtener respuesta
        curl_easy_setopt(curl, CURLOPT_URL, &url[0]);

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
        if (res != CURLE_OK){
            fprintf(stderr, "\nError al conectar con el servidor de blablacar.com.\n\nError: %s\n\n",
                curl_easy_strerror(res));
            return -2;
        }

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
    iPrice = 0;
    iName = 0;
    iDate = 0;
    iAge = 0;
    iScore = 0;

    // Se inicia el escaneo del código fuente
    yylex();

    // Se muestran los resultados obtendidos
    showData();
        
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
                    
    trip[iPrice].price = atof(&yytext[0]) + atof(&yytext[yyleng-2])/100;
    
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
    
    trip[iAge].age = atoi(&yytext[87]);
    
    iAge++;
    
}

void setScore(){
    
    // Se averigua si la cadena tiene "," o no
    char *c;
    int index;
    
    c = strchr(&yytext[37], ',');
    index = (int)(c-&yytext[37]);
        
    // Valor de la puntuación
    double s = atof(&yytext[36]);
    
    // Si tenía "," se suma el decimal
    if(index == 0){
        s += atof(&yytext[38])*0.1;
    }
        
    trip[iScore].score = s;
    
    iScore++;
    
}

void setRatings(){
      
    trip[iRatings].ratings = atoi(&yytext[24]);
    
    iRatings++;
    
}

int compare (struct Trip *trip1, struct Trip *trip2){
    
    int result = 0;
    
    // Se ordena por el precio
    if(trip1->price < trip2->price)
        result = -1;
    else if(trip1->price > trip2->price)
        result = 1;
    else{
        
        // En caso de tener el mismo precio se ordena por puntuación
        if(trip1->score > trip2->score)
            result = -1;
        else if(trip1->score < trip2->score)
            result = 1;
        else{
            
            // En caso de tener la misma puntuación se ordena por el número
            // de opiniones
            if(trip1->ratings > trip2->ratings)
                result = -1;
            else if(trip1->ratings < trip2->ratings)
                result = 1;
            
        }
        
    }

    return result;
  
}

void showData(){
   
    printf("\nResultados (por orden de salida):\n");
    
    for(int i=0; i<nTrip; i++){
        printf ("Viaje %d: Nombre-> %s, Precio-> %.2f€, Fecha-> %s, Edad: %d años, Puntuación: %.1f, Opiniones: %d\n", 
                i+1, trip[i].name, trip[i].price, trip[i].date, trip[i].age, trip[i].score, trip[i].ratings);
    }
    
    printf("\n\n");
    
    qsort((void *)&trip, nTrip, sizeof(struct Trip), (compfn)compare);
    
    printf("Te recomiendo que cojas el blablacar:\nNombre-> %s, Precio-> %.2f€, Fecha-> %s, Edad: %d años, Puntuación: %.1f, Opiniones: %d\n", 
                trip[0].name, trip[0].price, trip[0].date, trip[0].age, trip[0].score, trip[0].ratings);
    
    printf("\n\n");
    
}