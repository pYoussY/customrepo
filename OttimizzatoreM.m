clear
clc
format shortG;

%Inserire valore Iva e Markup in decimali
IVA=0.12;  
MarkUp=0.45;

NomeFileExcel="C:\Users\youssef stella\Desktop\Matteo gruppi acquisto\Brewing Point\costs\Brewing Point Matlab Con Dati già inseriti.xlsx";
Foglio="cost";
CellCost="A1:L522";

Inventory = readtable(NomeFileExcel,Sheet=Foglio,Range=CellCost)

Menu=readtable(NomeFileExcel,Sheet="Menu")

Recipe=readtable(NomeFileExcel,Sheet="recipe")

%computo costi totali per ciascun ingrediente nella ricetta e estrazione
%degli ingredienti senza prezzo
flagError=1;  
for i=1:height(Recipe)
    
    if isnan(Recipe{i,"PrezzoPerUnit_"})==1
    LogError(flagError,1)="L'ingrediente "+Recipe{i,"ingrediente"}+" alla riga "+i+" per la ricetta "+Recipe{i,"RicettaPer"}+" non ha un costo unitario definito, dunque non verrà preso in considerazione nel computo";
    LogError(flagError,2)=i;
    flagError=flagError+1;
    else
        Recipe{i,"PrezzoTotalePerLaRicetta"}=Recipe{i,"PrezzoPerUnit_"}*Recipe{i,"Quantita"};
    end
end
    

Recipe, LogError

%Suddivido la tabella Recipe in sotto tabelle in base alla ricetta
flag=2;
NewRecipe(1)=1;
for i=2:height(Recipe)
    if strcmp(Recipe{i,"RicettaPer"},Recipe{i-1,"RicettaPer"})==0
        NewRecipe(flag)=i;
        flag=flag+1;
    end
end
NewRecipe(end+1)=height(Recipe)+1;  %aggiungo la chiusura della ricetta (metto +1 per coerenza)

%individuo la ricetta per ogni voce del menù
flag=1;
for i=1:height(Menu)
    for j=1:length(NewRecipe)-1
        if strcmpi(Menu{i,"Prodotto"},Recipe{NewRecipe(j),"RicettaPer"})
            StartRowRecipe(flag)=NewRecipe(j);
            EndRowRecipe(flag)=NewRecipe(j+1)-1;


        end
    end
    flag=flag+1;
end

StartRowRecipe=StartRowRecipe.';        %INSERIRE ERROR QUALORA LA RICETTA NON VENGA TROVATA e evidenziare la cosa nel RecipeIndex O IN UN LOG ERROR
EndRowRecipe=EndRowRecipe.';

RecipeIndex=table(Menu{:,"Prodotto"},StartRowRecipe,EndRowRecipe, VariableNames=["Product", "Recipe Start Row", "Recipe End Row"]);

%computo i costi totali per ricetta, dati dalla somma dei costi per
%ingrediente prima calcolati

RecipeIndex{:,4}=zeros;
RecipeIndex=renamevars(RecipeIndex,"Var4","TotalCost");
Recipe
for i=1:height(RecipeIndex)
    ArrayCostLocal=zeros(RecipeIndex{i,"Recipe End Row"}-RecipeIndex{i,"Recipe Start Row"}+1,1);
    for j=1:height(ArrayCostLocal)
       ArrayCostLocal(j)=Recipe{RecipeIndex{i,"Recipe Start Row"}+j-1,"PrezzoTotalePerLaRicetta"} ;
        TotalCostLocal=sum(ArrayCostLocal,"omitnan");    %Omitnan serve per escludere dal computo i NaN, precedentemente individuati nel LogError
    RecipeIndex{i,"TotalCost"}=TotalCostLocal;
    Menu{i,"CostoTotaleYield"}=TotalCostLocal;
    end
end
RecipeIndex

%computo i prezzi i costi e i prezzi richiesti nella tabella Menu
for i=1:height(Menu)
    Menu{i,"CostoPerUnit_"}=Menu{i,"CostoTotaleYield"}/Menu{i,"Yield"};
    Menu{i,"Porzione_Costo"}=Menu{i,"CostoPerUnit_"}*Menu{i,"Porzione_Quantit_"};
    Menu{i,"Porzione_MarkupValore"}=Menu{i,"Porzione_Costo"}*MarkUp;
    Menu{i,"Porzione_PrezzoNetto"}=Menu{i,"Porzione_Costo"}+Menu{i,"Porzione_MarkupValore"};
    Tax=Menu{i,"Porzione_PrezzoNetto"}*IVA;
    Menu{i,"Porzione_PrezzoLordo"}=Menu{i,"Porzione_PrezzoNetto"}+Tax;
end
Menu

%NB Va valutata l'iterazione multipla data dai semilavorati come Arabic
%Spice, che andrebbe tolto dal computo del costo dei menu e indicato come
%semilavorato (per il calcolo finale basta un if ed escludere i
%semilavorati, ma nel computo iniziale dei costi per ogni ricetta è bene
%che la function prima lavori sui semilavorati e poi sugli altri, ma anche
%qui alcuni semilavorati contengono tra gli ingredienti altri
%semilavorati...) TROVARE UN MODO PER INDIVDUARE I "SEMILAVORATI ALLA
%SECONDA"

%andrebbe anche calcolato il costo per cottura e per lavoro

%Idee per optimization:
%1. indicare i prodotti con valore del markup più alto (NB NON in % ma val.
%assoluto), suddividendo in decili tutto il menu.
%2. indicare gli ingredienti meno usati e più costosi e i prodotti che
%usano tali ingredienti
%3. evidenziare i prodotti che usano tantissimi ingredienti e che portano
%un basso markup
%4. indicare un menu composto da X ricette che include prodotti ad
%alto markup assoluto e che usano ingredienti comuni agli altri

% Indico ingredienti meno usati
Ingredienti=table;          %Colonna 1= Nome ingredienti // Colonna 2= Conteggio ingredienti // Colonna 3= prezzo per unità 
Ingredienti{1,1}=Recipe{1,"ingrediente"};  %Il primo valore va inserito a mano prima del for loop
Ingredienti{1,2}=1;
Ingredienti{1,3}=Recipe{1,"PrezzoPerUnit_"};
Ingredienti=renamevars(Ingredienti,"Var1" ,"ingrediente");
Ingredienti=renamevars(Ingredienti,"Var2" ,"numero apparizioni nel menu");
Ingredienti=renamevars(Ingredienti,"Var3" ,"Prezzo per unita");
flag=2;   %NB partire da 2 poiché il primo l'abbiamo appena inserito a mano

for i=1:height(Recipe)
    IngredienteLocal=Recipe{i,"ingrediente"};
    PrezzoLocal=Recipe{i,"PrezzoPerUnit_"};
    Find=NaN;
    for j=1:height(Ingredienti)
        if strcmpi(IngredienteLocal,Ingredienti{j,1})==1    %NB nella colonna 1 di Ingredienti si inseriscono i nomi
            Find=1;
            RowFind=j;
        else Find=0;
        end
    end
    if Find==0
       Ingredienti{flag,1}=IngredienteLocal;
       Ingredienti{flag,2}=1;
       Ingredienti{flag,3}=PrezzoLocal;
       flag=flag+1;
    elseif Find==1
        Ingredienti{RowFind,2}=Ingredienti{RowFind,2}+1;
    end
end
Ingredienti
