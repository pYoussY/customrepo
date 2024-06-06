clear
clc
format shortG;

NomeFileExcel="C:\Users\youssef stella\Desktop\Matteo gruppi acquisto\Brewing Point\costs\Brewing Point Matlab.xlsx";
Foglio="cost";
Celle="A1:L522";

Inventory = readtable(NomeFileExcel,Sheet=Foglio,Range=Celle)

Menu=readtable("Brewing Point Matlab.xlsx",Sheet="Menu")

Recipe=readtable("Brewing Point Matlab.xlsx",Sheet="recipe")

%NB quando si comparano tabelle diverse usare strcmpi anziché strcmp poiché il primo non è case sensitive

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

RecipeIndex=table(Menu{:,"Prodotto"},StartRowRecipe,EndRowRecipe, VariableNames=["Product", "Recipe Start Row", "Recipe End Row"])

% primo collegamento tra foglio Inventory e foglio Recipe dei costi per
% ogni ingrediente della ricetta, usando i nomi completi

RowLogError1=1;
for i=1:height(Recipe)
    flagError=0;

    for j=1:height(Inventory)
        if strcmpi(Recipe{i,"ingrediente"},Inventory{j,"Nome"})==1
            flagError=1;
            Recipe(i,"PrezzoPerUnit_")=Inventory(j,"PrezzoPerUnita");
        end
    end
    if flagError==0
        LogError1{RowLogError1,1}="L'ingrediente "+Recipe{i,"ingrediente"}+" alla riga "+i+" per la ricetta "+Recipe{i,"RicettaPer"}+" non è stato trovato";
        LogError1{RowLogError1,2}=i;
        RowLogError1=RowLogError1+1;
    end
end
Recipe,LogError1

% Secondo collegamento tra foglio Inventory e foglio Recipe dei costi per
% ogni ingrediente della ricetta, usando i nomi splittati dove si trova lo
% spazio o il trattino

%%splitto la parola non trovata (indicata nel LogError1 precedente) nel punto dove c'è lo spazio, dopodiche cerca la frase splittata, ad
%%esempio sia "Canola" che "Oil", con strfind e matchare con chi da un
%%doppio ok 1-1  (ovvero in tot riga ho trovato sia Oil che Canola dunque Canola
%%Oil si trova in tale riga, NB nel finale invece di indicare solo 0-1 o 1-1 indica la riga dove trova la parola))
% Dopodiché creare nuovo LogError1 con le avanzanti (ovvero con 1-0 (trovato Canola ma non Oil), 0-1 (trovato Oil
%%ma non Canola) oppure 0-0 (non ha trovato ne Oil ne Canola)


for i=1:height(LogError1)
    NewString{i,:}=split(Recipe{LogError1{i,2},"ingrediente"}, [" ","-"]);     %split del nome allo spazio o a -
end


for i=1:height(NewString)                   %Cerca stringhe nell'Inventory
    LocalString=NewString{i};
    flag=1;
    LocalStringFound=nan;
    for j=1:height(LocalString)
        for k=1:height(Inventory)
            StringInventory=Inventory{k,"Nome"};
            StringInventory=StringInventory{:};

            if strfind(StringInventory,LocalString(j))~=0
                LocalStringFound(flag,j)=k;               %LocalStringFound è una matrice che indica le righe k su Inventory  in cui ha trovato la singola parola (ogni colonna è una parola, ogni riga aggiunta è una riga K)
                flag=flag+1;
            end
        end
    end
    flagMatch=1;
    if width(LocalStringFound)==1 && height(LocalStringFound)>1  %serve per inserire i match trovati composti di una sola parola nel successivo logerror2
        NewString{i,2}=LocalStringFound;
    else
        for j1=1:(width(LocalStringFound)-1)        %quadruplo ciclo for per cercare nella matrice LocalStringFound quando ci sono righe k uguale su diverse colonne (ovvero, quando per un ingrediente di 3 parole (dunque 3 colonne) si trova uno stesso valore su tutte le colonne allora quel valore indica la riga su Inventory in cui sono presenti tutte quelle parole assieme contemporaneamente
            LocalStringFoundCount=zeros;
            for i1=1:height(LocalStringFound)
                if j1<width(LocalStringFound)
                    for j2=j1+1:width(LocalStringFound)

                        for i2=1:height(LocalStringFound)
                            if LocalStringFound(i1,j1)==LocalStringFound(i2,j2) && LocalStringFound(i1,j1)~=0 && isnan(LocalStringFound(i1,j1))==0
                                LocalStringFoundCount(flagMatch,1)=LocalStringFound(i1,j1);
                                LocalStringFoundCount(flagMatch,2)=LocalStringFound(i2,j2);
                                flagMatch=flagMatch+1;


                            end
                        end
                    end

                end
            end
            if LocalStringFoundCount~=0         %Se ha trovato qualcosa lo segna nel NewString
                NewString{i,2}=LocalStringFoundCount;
            else                                %Questo serve per gli ingredienti formati da DUE o + parole per le quali non si è trovato il match (ovvero si trovano solo soluzioni 1-0 oppure 0-1 ma mai 1-1
                for ii=1:height(LocalStringFound)
                    for jj=1:width(LocalStringFound)
                        if LocalStringFound(ii,jj)~=0
                            LocalStringFound2(ii)=LocalStringFound(ii,jj);
                        end
                    end
                end

                NewString{i,2}=LocalStringFound2;
            end
        end
    end
end

NewString       %i match sono solo quegli array nella colonna 2 composti da due numeri uguali

%ora recupero i prezzi dei nuovi match

NewString{19,2}

NewString(:,3)=LogError1(:,2);
flag=0;
for i=1:height(NewString)
    if length(NewString{i,2})==2 && NewString{i,2}(1)==NewString{i,2}(2)  %Se precedentemente ha trovato una coppia di parole uguali alla medesima riga di inventory estrae il prezzo da inventory e lo mette in recipe
        RowNewString=NewString{i,2};
        RowNewString=RowNewString(1);
        Recipe{LogError1{i,2},"PrezzoPerUnit_"}=Inventory{RowNewString,"PrezzoPerUnita"};
    elseif length(NewString{i,2})>2             %Se trova coppie di più risultati diversi inserisce nel logError le righe in cui ha trovato quelle parole
        flag=flag+1;
        RecipeError=Recipe{NewString{i,3},"ingrediente"};
        RecipeError=RecipeError{:};
        RecipeRowError=Recipe{NewString{i,3},"RicettaPer"};
        RecipeRowError=RecipeRowError{:};
        LogError2{flag,1}="L'ingrediente "+RecipeError+" per la ricetta "+RecipeRowError+" è stato trovato su più righe dell'Inventory, indicate di seguito";
        LogError2{flag,2}=NewString{i,2};
    elseif length(NewString{i,2})<2 && NewString{i,2}==0        %se non trova match validi mette in logError
        flag=flag+1;
        LogError2{flag,1}="L'ingrediente "+Recipe{NewString{i,3},"ingrediente"}+" per la ricetta "+Recipe{NewString{i,3},"RicettaPer"}+" non è stato trovato";
        LogError2{flag,2}="non trovato";
    elseif length(NewString{i,2})>=1 && NewString{i,2}(1)~=0    %se trova risultati diversi ma non accoppiati (ovvero per ingredienti composti da una sola parola)
        RecipeError=Recipe{NewString{i,3},"ingrediente"};
        RecipeError=RecipeError{:};
        RecipeRowError=Recipe{NewString{i,3},"RicettaPer"};
        RecipeRowError=RecipeRowError{:};
        LogError2{flag,1}="L'ingrediente "+RecipeError+" per la ricetta "+RecipeRowError+" è stato trovato su più righe dell'Inventory, indicate di seguito";
        LogError2{flag,2}=NewString{i,2};
    end
end

Recipe,LogError2

% AGGIUNGERE DEPERIBILITA (VEDI I VEGETABLES)






