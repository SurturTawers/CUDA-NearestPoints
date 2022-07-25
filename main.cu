#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <algorithm>
#include <chrono>
using namespace std;
struct p3D{
    int pt_num;
    float x;
    float y;
    float z;
};
p3D* crearP3D(float* coords){
    p3D* point=new p3D;
    point->pt_num=coords[0];
    point->x=coords[1];
    point->y=coords[2];
    point->z=coords[3];
    return point;
}
int getInput(string input, float* params){
    int inputSize=input.length(), i=0, k=0;
    string aux;
    while(i<inputSize){ //Guardo uno a uno los parametros en el string aux
        while(input[i]!=' ' && i<inputSize){ // mientras no se encuentre un espacio y no sobrepase el tamaño del input
            aux.push_back(input[i]);
            i++;
        }
        if(aux.size()!=0){ //si hay algún parametro
            params[k]= stof(aux); //lo transformo de string a float y lo guardo en params
            aux.clear();
            k++;
        }
        i++;
    }
    if(k!=4){   //verifico que hayan 4 parámetros
        cout<<"Numero incorrecto de parametros: "<<k<<" de 4"<<endl;
        return 0;
    }
    for(int z=0;z<4;z++){ //verifico que sean valores positivos
        if(params[z]<=0){
            cout<<"Ingrese valores positivos y mayores a cero -> "<<params[z]<<endl;
            return 0;
        }
    }
    if(params[3]>params[0]){
        cout<<"[T] debe ser menor o igual a [N]: "<<params[3]<<" > "<<params[0]<<endl;
        return 0;
    }
    if(params[1]>params[0]){
        cout<<"[K] debe ser menor o igual a [N]: "<<params[1]<<" > "<<params[0]<<endl;
        return 0;
    }
    if(params[0]-floor(params[0])){
        cout<<"Ingrese un numero entero por favor -> "<<params[0]<<endl;
        return 0;
    }
    if(params[1]-floor(params[1])){
        cout<<"Ingrese un numero entero por favor -> "<<params[1]<<endl;
        return 0;
    }
    if(params[3]-floor(params[3])){
        cout<<"Ingrese un numero entero por favor -> "<<params[3]<<endl;
    }
    return 1;
}
void getPoints(string* points, p3D** puntos, int N){
    float coords[4];
    int tam,k=0,j=0;
    string aux;
    for(int i=0;i<N;i++){//i<748720
        tam=points[i].length();
        while(k<tam){//Obtengo los puntos y las coordenadas en el string aux
            while(points[i][k]!=' ' && k<tam){
                aux.push_back(points[i][k]);
                k++;
            }
            if(aux.size()!=0){
                coords[j]=stof(aux);
                aux.clear();
                j++;
            }
            k++;
        }
        puntos[i]=crearP3D(coords);
        k=0;
        j=0;
    }
}
void printPoints(p3D** points, int N){
    cout<<"\n------------PUNTOS------------"<<endl;
    cout<<"pt_num\t\tx\t\t\ty\t\t\tz"<<endl;
    for(int i=0;i<N;i++){//i<748720
        cout<<points[i]->pt_num<<"\t\t"<<points[i]->x<<"\t\t"<<points[i]->y<<"\t\t"<<points[i]->z<<endl;
    }
}
void printSolution(p3D* sol, int K){
    cout<<"\n------------SOLUCION------------"<<endl;
    cout<<"pt_num\t\tx\t\t\ty\t\t\tz"<<endl;
    for(int i=0;i<K;i++){//i<748720
        if(sol[i].pt_num!=0){
            cout<<sol[i].pt_num<<"\t\t"<<sol[i].x<<"\t\t"<<sol[i].y<<"\t\t"<<sol[i].z<<endl;
        }
    }
}
void choosePoints(p3D* chosen, p3D** points, int K, int N){
    int seleccionados[K],num,j=0;
    fill(seleccionados,seleccionados+K,0);
    for(int i=0;i<K;i++){
        num=rand()%N;//obtengo un punto aleatorio
        while(seleccionados[j]!=0 && j<K){
            if(seleccionados[j]==num){//si ya he seleccionado algun punto, seleccion otro
                num=rand()%N;//748720
                j=0;
            }else{
                j++;
            }
        }
        seleccionados[j]=num;
        chosen[i]=*points[num];
    }
}
__global__ void search(p3D* d_points, p3D* d_chosen, p3D* d_solution, int N, int K, float d_m , int T){
    int thid= blockIdx.x * blockDim.x  + threadIdx.x;
    int jmp=blockDim.x*gridDim.x;
    int z=0,k=0;
    float dist,d_x,d_y,d_z;
    __shared__ int cardVec;
    while(k<K){
        for(int j=thid;j<N;j+=jmp){
            d_x= powf(d_chosen[k].x - d_points[j].x,2.0);
            d_y= powf(d_chosen[k].y - d_points[j].y,2.0);
            d_z= powf(d_chosen[k].z - d_points[j].z,2.0);
            dist= sqrtf(d_x + d_y + d_z);
            if(dist<=d_m){
                atomicAdd(&cardVec,1);
            }
        }
        __syncthreads();
        if(cardVec>=T){//si la cardinalidad del punto actual de chosen es mayor a T
            d_solution[z]=d_chosen[k];//lo agrego al arreglo de soluciones
            z++;
        }
        k++;
        cardVec=0;
        __syncthreads();
    }
    __syncthreads();
}
void searchPoints(p3D** points, int N,int K, float d_m, int T){
    int blocks=10,threads=1020;
    p3D* pts=new p3D[N];
    for(int i=0;i<N;i++){
        pts[i]= *points[i];
    }
    p3D* chosen=new p3D[K];
    choosePoints(chosen,points,K,N);//elige los K puntos aleatoriamente
    //seleccioanr si mostrar los puntos elegidos
    string input;
    int option;
    cout<<"\nMostrar puntos elegidos?\n[1]: Si\t[2]: No"<<endl;
    getline(cin,input);
    option=stoi(input);
    while(option!=1 && option!=2){
        cout<<"\nIngrese una opcion valida\nMostrar puntos elegidos?\n[1]: Si\t[2]: No"<<endl;
        getline(cin,input);
        option=stoi(input);
    }
    if(option==1){
        cout<<"\n------------PUNTOS SELECCIONADOS------------"<<endl;
        cout<<"pt_num\t\tx\t\t\ty\t\t\tz"<<endl;
        for(int i=0;i<K;i++){
            cout<<chosen[i].pt_num<<"\t\t"<<chosen[i].x<<"\t\t"<<chosen[i].y<<"\t\t"<<chosen[i].z<<endl;
        }
    }
    p3D* sol=new p3D[K];
    p3D* d_chosen;
    p3D* d_pts;
    p3D* d_sol;
    cudaMalloc(&d_sol,K*sizeof(p3D));
    cudaMalloc(&d_pts,N*sizeof(p3D));
    cudaMalloc(&d_chosen,K*sizeof(p3D));
    cudaMemcpy(d_pts,pts,sizeof(p3D)*N,cudaMemcpyHostToDevice);
    cudaMemcpy(d_chosen,chosen,sizeof(p3D)*K,cudaMemcpyHostToDevice);
    double total=0;
    auto start=chrono::high_resolution_clock::now();
    auto end=chrono::high_resolution_clock::now();
    auto time=chrono::duration_cast<chrono::nanoseconds>(end-start).count();
    for(int i=0;i<50;i++){
        start=chrono::high_resolution_clock::now();
        search<<<blocks,threads>>>(d_pts,d_chosen,d_sol,N,K,d_m,T);
        end=chrono::high_resolution_clock::now();
        time=chrono::duration_cast<chrono::nanoseconds>(end-start).count();
        total+=time;
    }
    cudaMemcpy(sol,d_sol,K*sizeof(p3D),cudaMemcpyDeviceToHost);
    cudaFree(d_pts);
    cudaFree(d_chosen);
    cudaFree(d_sol);
    printSolution(sol,K);
    cout<<"\nTiempo para 50 ejecuciones con "<<blocks<<" bloques y "<<threads<<" hebras: "<<total<<" ns\nPromedio: "<<total/(float)50<<" ns"<<endl;
    delete[] pts;
    delete[] sol;
    delete[] chosen;
}
int main() {
    ifstream puntos;
    puntos.open("/tmp/tmp.iC2UmBBVO8/puntos3D.txt"); //Cambiar por la ruta en la que se encuentra el archivo puntos3D.txt
    if(puntos.is_open()){
        string input;
        float params[4];
        cout<<"Ingrese los valores separados por un espacio\n[N]:\ttamaño del conjunto de puntos (maximo 748742)\n[K]:\tnumero de puntos a analizar.\n[d_m]:\tdistancia máxima entre puntos.\n[T]:\tcardinalidad mínima de la vecindad."<<endl;
        getline(cin,input);
        if(getInput(input,params)){
            int N=params[0],K=params[1];
            srand(time(NULL));
            string* point=new string[N];
            p3D** points=new p3D*[N];
            for(int i=0;i<N;i++){
                getline(puntos,point[i]);
            }
            getPoints(point,points,N);
            string input;
            int option;
            cout<<"\nMostrar puntos?\n[1]: Si\t[2]: No"<<endl;
            getline(cin,input);
            option=stoi(input);
            while(option!=1 && option!=2){
                cout<<"\nIngrese una opcion valida\nMostrar puntos?\n[1]: Si\t[2]: No"<<endl;
                getline(cin,input);
                option=stoi(input);
            }
            if(option==1){
                printPoints(points, N);
            }
            searchPoints(points,N,K,params[2],params[3]);
            cout<<"\nAdios :)"<<endl;
            for(int i=0;i<N;i++){
                delete[] points[i];
            }
            delete[] point;
        }else{
            cout<<"Adios :("<<endl;
            puntos.close();
            return 0;
        }
    }else{
        cout<<"No se pudo leer el archivo con los puntos :( adios"<<endl;
    }
    puntos.close();
    return 0;
}