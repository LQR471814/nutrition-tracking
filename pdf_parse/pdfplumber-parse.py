import pdfplumber

with pdfplumber.open("./retn06.pdf") as pdf:
    p = pdf.pages[6]
    for w in p.extract_words():
        print(w['text'])
