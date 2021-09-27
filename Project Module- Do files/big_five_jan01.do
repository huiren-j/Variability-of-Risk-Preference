***** BIG FIVE *************************

* THE DESCRIPTION OF THE BIG FIVE TEST IS IN GERLITZ AND SCHUPP (2005); DIW RESEARCH NOTES 4

* G  vp12501: gründlich arbeitet
* E  vp12502: kommunikativ, gesprächig ist
* V- vp12503: manchmal etwas grob zu anderen ist
* O  vp12504: originell ist, neue Ideen einbringt
* N  vp12505: sich oft Sorgen macht
* V  vp12506: verzeihen kann
* G- vp12507: eher faul ist
* E  vp12508: aus sich herausgehen kann, gesellig ist
* O  vp12509: künstlerische Erfahrungen schätzt
* N  vp12510: leicht nervös wird
* G  vp12511: Aufgaben wirksam und effizient erledigt
* E- vp12512: zurückhaltend ist
* V  vp12513: rücksichtsvoll und freundlich mit anderen umgeht
* O  vp12514: eine lebhafte Phantasie, Vorstellungen hat
* N- vp12515: entspannt ist, mit Stress gut umgehen kann

*plh0212: Thorough worker
*plh0213: Am communicative
*plh0214: Coarse
*plh0215: Original
*plh0216: Worry a lot
*plh0217: Able to forgive
*plh0218: Tend to be lazy
*plh0219: Sociable
*plh0220: Value artistic experiences 
*plh0221: Somewhat nervous
*plh0222: Carry out tasks efficiently
*plh0223: Reserved
*plh0224: Friendly with others 
*plh0225: Have lively imagination
*plh0226: Deal with stress 

for num 2/9: replace plh021X=. if plh021X<0
for num 0/6: replace plh022X=. if plh022X<0

*REVERSE THE SCALE FOR "NEGATIVE" ITEMS
*plh0226: Deal with stress 
g plh0226r=1 if plh0226==7
replace plh0226r=2 if plh0226==6
replace plh0226r=3 if plh0226==5
replace plh0226r=4 if plh0226==4
replace plh0226r=5 if plh0226==3
replace plh0226r=6 if plh0226==2
replace plh0226r=7 if plh0226==1

*reserved to extravert
g plh0223r=1 if plh0223==7
replace plh0223r=2 if plh0223==6
replace plh0223r=3 if plh0223==5
replace plh0223r=4 if plh0223==4
replace plh0223r=5 if plh0223==3
replace plh0223r=6 if plh0223==2
replace plh0223r=7 if plh0223==1

*Coarse to not rude
g plh0214r=1 if plh0214==7
replace plh0214r=2 if plh0214==6
replace plh0214r=3 if plh0214==5
replace plh0214r=4 if plh0214==4
replace plh0214r=5 if plh0214==3
replace plh0214r=6 if plh0214==2
replace plh0214r=7 if plh0214==1

*plh0218: Tend to be lazy
g plh0218r=1 if plh0218==7
replace plh0218r=2 if plh0218==6
replace plh0218r=3 if plh0218==5
replace plh0218r=4 if plh0218==4
replace plh0218r=5 if plh0218==3
replace plh0218r=6 if plh0218==2
replace plh0218r=7 if plh0218==1

*"Conscientiousness": *plh0222: Carry out tasks efficiently  + *plh0212: Thorough worker + *plh0218: Tend to be lazy
*"Extraversion": *plh0223: Reserved (reversed) + *plh0213: Am communicative + *plh0219: Sociable
*"Agreeableness": *plh0224: Friendly with others + *plh0214r + *plh0217: Able to forgive
*"Openness to experience": *plh0225: Have lively imagination + *plh0220: Value artistic experiences + *plh0215: Original
*"Neuroticism":*plh0221: Somewhat nervous + *plh0216: Worry a lot + + *plh0226: Deal with stress

* GENERATE BIG FIVE MEASURES BY ADDING UP SCORES
g bigfive_g=plh0222+plh0212+plh0218r
g bigfive_e=plh0223r+plh0213+plh0219
g bigfive_v=plh0214r+plh0217+plh0224
g bigfive_o=plh0215+plh0225+plh0220
g bigfive_n=plh0216+plh0221+plh0226r

label variable bigfive_g  "Conscientiousness"
label variable bigfive_e  "Extraversion"
label variable bigfive_v  "Agreeableness"
label variable bigfive_o  "Openness to experience"
label variable bigfive_n  "Neuroticism"

* STANDARDIZING BIG FIVE MEASURES
egen std_bigfive_g=std(bigfive_g)
egen std_bigfive_e=std(bigfive_e)
egen std_bigfive_v=std(bigfive_v)
egen std_bigfive_o=std(bigfive_o)
egen std_bigfive_n=std(bigfive_n)

label variable std_bigfive_g  "Std. Conscientiousness"
label variable std_bigfive_e  "Std. Extraversion"
label variable std_bigfive_v  "Std. Agreeableness"
label variable std_bigfive_o  "Std. Openness to experience"
label variable std_bigfive_n  "Std. Neuroticism"

