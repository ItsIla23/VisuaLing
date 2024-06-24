/*
import SwiftUI
import CoreML
import Vision
import Alamofire

// Definizione della struttura per la risposta della traduzione
struct TranslationResponse: Decodable {
    let translations: [Translation]
}

// Definizione della struttura per una singola traduzione
struct Translation: Decodable {
    let text: String
}


struct Line: Shape {
    var start: CGPoint
    var end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}
 
 


struct CameraView: View {
    
    @State var isRequired: Bool = false
    @State private var selectedLanguage = "EN"
    @State private var lastSelectedLanguage = "EN" // Memorizza l'ultima lingua selezionata
    
    let languages = ["EN", "IT", "ES"] // Aggiornato IT per l'italiano
    
    @StateObject private var model = FrameHandler()
    
    let imageClassifier = ImageClassifier()
    
    @State private var classificationLabel: String = ""
    @State private var translatedWord: String = ""
    @State private var isShowingDetectableItemsView = false
    @State private var requestAvailable = false
    
    @State private var started = false
    
    @State var objectToSearch: String = ""
    
    @State private var lineColor: Color = Color(red: 0.51, green: 0.65, blue: 0.48)
    
    private func startClassifying() {
        while started {
            classifyCurrentFrame()
            sleep(1)
        }
    }
    
    private func findMode() {
        print("no detection")
    }
    
    private func updateClassificationLabel(_ newValue: String) {
        guard let commaIndex = newValue.firstIndex(of: ",") else {
            // If no comma is found, update with the entire string
            self.classificationLabel = newValue
            return
        }
        let substringBeforeComma = newValue[..<commaIndex]
        self.classificationLabel = String(substringBeforeComma)
    }
    
    private func classifyCurrentFrame() {
        guard let frame = model.frame else { return }
        let image = UIImage(cgImage: frame)
        do {
            try self.imageClassifier.makePredictions(
                for: image,
                completionHandler: imagePredictionHandler
            )
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }
    
    private func imagePredictionHandler(_ predictions: [ImageClassifier.Prediction]?) {
        guard let predictions = predictions else {
            print("No predictions. (Check console log.)")
            return
        }
        
        print(predictions[0].classification)
        
        guard let classification = predictions.first?.classification else {
            return
        }
        
        // Estrai l'intera stringa fino alla virgola
        updateClassificationLabel(classification)
        
        print(predictions[0].confidencePercentage)
        if (Double(predictions[0].confidencePercentage)! > 0.2) {
            // Traduci la parola corrente nella lingua selezionata
            isRequired = true
            spawnRectangle(spawnIsRequired: isRequired, predictions)
            
        } else {
            print("Discarded!")
        }
    }
    
    func spawnRectangle(spawnIsRequired: Bool, _ predictions: [ImageClassifier.Prediction]?) -> (any View) {
        if(spawnIsRequired) {
            translateWord(classificationLabel)
            return ZStack {
                Rectangle()
                    .frame(width: 100, height: 100, alignment: .center)
                    .foregroundStyle(.green)
            }
        }
        return Rectangle()
            .frame(width: 100, height: 100, alignment: .center)
            .foregroundStyle(.blue)
    }
    
    private func translateWord(_ word: String) {
        let apiKey = "87176f3b-edc8-4e46-979e-ffb439087dca:fx" // Inserita la chiave API
        let targetLanguage = selectedLanguage.lowercased() // Utilizza la lingua selezionata
        let url = "https://api-free.deepl.com/v2/translate"
        let parameters: [String: Any] = [
            "text": word,
            "target_lang": targetLanguage,
            "auth_key": apiKey
        ]
        
        AF.request(url, method: .post, parameters: parameters).responseDecodable(of: TranslationResponse.self) { response in
            switch response.result {
            case .success(let translationResponse):
                // Memorizza la traduzione nella lingua selezionata
                DispatchQueue.main.async {
                    self.translatedWord = translationResponse.translations.first?.text ?? ""
                }
            case .failure(let error):
                print("Errore nella traduzione: \(error.localizedDescription)")
                if let data = response.data {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Dati di risposta:", responseString ?? "Dati non validi")
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in // Utilizza GeometryReader per ottenere l'altezza dello schermo
                ZStack{
                    if(isRequired) {
                        ZStack {
                            
                            // Angoli superiori (verdi)
                            Line(start: CGPoint(x: -40, y: 0), end: CGPoint(x: 20, y: 0))
                                .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                                .offset(x: 330, y: 100)
                            Line(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 50))
                                .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                                .offset(x: 350, y: 97)
                            
                            Line(start: CGPoint(x: 60, y: 0), end: CGPoint(x: 0, y: 0))
                                .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                                .offset(x: 40, y: 100)
                            Line(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 50))
                                .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                                .offset(x: 37, y: 97)
                            
                            // Angoli inferiori
                            Line(start: CGPoint(x: -40, y: 0), end: CGPoint(x: 20, y: 0))
                                .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                                .offset(x: 330, y: 650)
                            Line(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 50))
                                .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                                .offset(x: 350, y: 603)
                            
                            Line(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 60, y: 0))
                                .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                                .offset(x: 37, y: 650)
                            Line(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y:50))
                                .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                                .offset(x: 37, y: 603)
                        }
                       
                        
                        VStack {
                            HStack {
                                Spacer().frame(width: 260) // Spazio vuoto per spingere il picker a destra
                                Picker("...", selection: $selectedLanguage) {
                                    ForEach(languages, id: \.self) { language in
                                        Text(language)
                                            .foregroundColor(.black)
                                            .bold()
                                            .font(.title2)
                                    }
                                }
                                .frame(width: 80, height: 40)
                                .background(Color.white)
                                .cornerRadius(15)
                                .pickerStyle(MenuPickerStyle())
                                .accentColor(.black)
                                .onChange(of: selectedLanguage) { newLanguage in
                                    // Memorizza l'ultima lingua selezionata solo se è diversa dalla lingua attualmente selezionata
                                    if newLanguage != lastSelectedLanguage {
                                        lastSelectedLanguage = newLanguage
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing) // Estende il picker fino al massimo possibile a destra
                            }
                            .padding() // Aggiungi spazio intorno all'intero HStack
                            // Aggiungi sfondo blu al VStack
                            
                            Spacer()
                            
                            if !translatedWord.isEmpty {
                                HStack {
                                    Text(translatedWord)
                                        .font(.title)
                                        .foregroundColor(.black) // Testo nero
                                        .bold()
                                        .frame(maxWidth: .infinity) // Estendi in larghezza
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                    
                                    Image(systemName: "speaker.wave.2.circle")
                                        .resizable()
                                        .foregroundColor(.black)
                                        .frame(width: 25, height: 25)
                                }
                        
                                .padding(.horizontal, 60)
                                
                                .accessibilityHidden(true)
                                .background(
                                    Rectangle()
                                        .foregroundColor(.white) // Sfondo bianco
                                        .opacity(0.9)
                                        .frame(height: 110) // Fissa l'altezza
                                )
                                
                            } else {
                                Text("                 ")
                                    .font(.title)
                                    .foregroundColor(.black) // Testo nero
                                    .bold()
                                    .frame(maxWidth: .infinity) // Estendi in larghezza
                                    .background(
                                        Rectangle()
                                            .foregroundColor(.white) // Sfondo bianco
                                            .opacity(0.9)
                                            .frame(height: 110) // Fissa l'altezza
                                    )
                                    .padding(.all, -30) // Aggiungi spazio ai lati e in basso
                                    .edgesIgnoringSafeArea(.bottom) // Ignora lo spazio sicuro in basso
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
                .frame(height: geometry.size.height) // Fissa l'altezza della VStack a quella dello schermo
            }
            .background {
                FrameView(image: model.frame)
                    .ignoresSafeArea() // Ignora lo spazio sicuro
                    .accessibilityHidden(true)
            }
        }
        .onAppear() {
            if !started {
                started = true
                DispatchQueue.global(qos: .background).async(execute: startClassifying)
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
*/

import SwiftUI
import CoreML
import Vision
import Alamofire
import AVFoundation // Importa AVFoundation per utilizzare il sintetizzatore vocale

// Definizione della struttura per la risposta della traduzione
struct TranslationResponse: Decodable {
    let translations: [Translation]
}

// Definizione della struttura per una singola traduzione
struct Translation: Decodable {
    let text: String
}

struct Line: Shape {
    var start: CGPoint
    var end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}

struct CameraView: View {
    
    @State private var selectedLanguage = "EN"
    @State private var lastSelectedLanguage = "EN" // Memorizza l'ultima lingua selezionata
    
    let languages = ["EN", "IT", "ES"] // Aggiornato IT per l'italiano
    
    @StateObject private var model = FrameHandler()
    
    let imageClassifier = ImageClassifier()
    
    @State private var classificationLabel: String = ""
    @State private var translatedWord: String = ""
    @State private var isShowingDetectableItemsView = false
    @State private var requestAvailable = false
    
    @State private var started = false
    
    @State var objectToSearch: String = ""
    
    @State private var lineColor: Color = Color(red: 0.51, green: 0.65, blue: 0.48)
    
    private func startClassifying() {
        while started {
            classifyCurrentFrame()
            sleep(1)
        }
    }
    
    private func findMode() {
        print("no detection")
    }
    
    private func updateClassificationLabel(_ newValue: String) {
        guard let commaIndex = newValue.firstIndex(of: ",") else {
            // If no comma is found, update with the entire string
            self.classificationLabel = newValue
            return
        }
        let substringBeforeComma = newValue[..<commaIndex]
        self.classificationLabel = String(substringBeforeComma)
    }
    
    private func classifyCurrentFrame() {
        guard let frame = model.frame else { return }
        let image = UIImage(cgImage: frame)
        do {
            try self.imageClassifier.makePredictions(
                for: image,
                completionHandler: imagePredictionHandler
            )
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }
    
    private func imagePredictionHandler(_ predictions: [ImageClassifier.Prediction]?) {
        guard let predictions = predictions else {
            print("No predictions. (Check console log.)")
            return
        }
        
        print(predictions[0].classification)
        
        guard let classification = predictions.first?.classification else {
            return
        }
        
        // Estrai l'intera stringa fino alla virgola
        updateClassificationLabel(classification)
        
        print(predictions[0].confidencePercentage)
        if (Double(predictions[0].confidencePercentage)! > 0.2) {
            // Traduci la parola corrente nella lingua selezionata
            translateWord(classificationLabel)
        } else {
            print("Discarded!")
        }
    }
    
    private func translateWord(_ word: String) {
        let apiKey = "87176f3b-edc8-4e46-979e-ffb439087dca:fx" // Inserita la chiave API
        let targetLanguage = selectedLanguage.lowercased() // Utilizza la lingua selezionata
        let url = "https://api-free.deepl.com/v2/translate"
        let parameters: [String: Any] = [
            "text": word,
            "target_lang": targetLanguage,
            "auth_key": apiKey
        ]
        
        AF.request(url, method: .post, parameters: parameters).responseDecodable(of: TranslationResponse.self) { response in
            switch response.result {
            case .success(let translationResponse):
                // Memorizza la traduzione nella lingua selezionata
                DispatchQueue.main.async {
                    self.translatedWord = translationResponse.translations.first?.text ?? ""
                }
            case .failure(let error):
                print("Errore nella traduzione: \(error.localizedDescription)")
                if let data = response.data {
                    let responseString = String(data: data, encoding: .utf8)
                    print("Dati di risposta:", responseString ?? "Dati non validi")
                }
            }
        }
    }
    
    // Funzione per far leggere il testo dal sintetizzatore vocale
    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT") // Imposta la lingua italiana
        utterance.rate = 0.5 // Imposta la velocità di lettura
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in // Utilizza GeometryReader per ottenere l'altezza dello schermo
                ZStack {
                    if !classificationLabel.isEmpty {
                        
                        // Angoli superiori (verdi)
                        Line(start: CGPoint(x: -40, y: 0), end: CGPoint(x: 20, y: 0))
                            .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                            .offset(x: 330, y: 100)
                        Line(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 50))
                            .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                            .offset(x: 350, y: 97)
                        
                        Line(start: CGPoint(x: 60, y: 0), end: CGPoint(x: 0, y: 0))
                            .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                            .offset(x: 40, y: 100)
                        Line(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 50))
                            .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                            .offset(x: 37, y: 97)
                        
                        // Angoli inferiori
                        Line(start: CGPoint(x: -40, y: 0), end: CGPoint(x: 20, y: 0))
                            .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                            .offset(x: 330, y: 650)
                        Line(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 50))
                            .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                            .offset(x: 350, y: 603)
                        
                        Line(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 60, y: 0))
                            .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                            .offset(x: 37, y: 650)
                        Line(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y:50))
                            .stroke(lineColor, lineWidth: 6) // Imposta il colore del bordo e lo spessore
                            .offset(x: 37, y: 603)
                    }
                }
                VStack {
                    VStack {
                        HStack {
                            Picker("...", selection: $selectedLanguage) {
                                ForEach(languages, id: \.self) { language in
                                    Text(language)
                                        .foregroundColor(.white)
                                        .bold()
                                        .font(.title)
                                }
                            }
                            .frame(width: 80, height: 40)
                            .background(Color.black)
                            .opacity(0.7)
                            .cornerRadius(15)
                            .pickerStyle(MenuPickerStyle())
                            .accentColor(.white)
                            .onChange(of: selectedLanguage) { newLanguage in
                                // Memorizza l'ultima lingua selezionata solo se è diversa dalla lingua attualmente selezionata
                                if newLanguage != lastSelectedLanguage {
                                    lastSelectedLanguage = newLanguage
                                }
                            }
                            .colorScheme(.dark)
                            
                            .frame(maxWidth: .infinity, alignment: .trailing) // Estende il picker fino al massimo possibile a destra
                        }
                    }
                    .padding(.horizontal, 0)
                    .padding (.vertical, 30)
                    
                    
                    Spacer ()
                    if !translatedWord.isEmpty {
                        HStack {
                            Spacer()
                                .frame(width: 18)
                            Text(translatedWord)
                                .font(.title)
                                .foregroundColor(.white)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                
                            
                            // Aggiungi il pulsante per far leggere il classification label
                            Button(action: {
                                speakText(classificationLabel)
                            }) {
                                Image(systemName: "speaker.wave.2.circle")
                                    .resizable()
                                    .frame(width: 45, height: 45)
                                    .foregroundColor(.white)
                                    .font(.title)
                            }
                        }.padding (.horizontal, 20)
                         .padding(.vertical, 9)
                        .background(
                            
                            Rectangle()
                                .frame(width: 800, height: 130)
                                .foregroundColor(.black)
                                .opacity(0.7)
                        )
                      
                        .edgesIgnoringSafeArea(.bottom)
                        .accessibilityHidden(true)
                    } else {
                        Text("     ")
                            .font(.title)
                            .foregroundColor(.white)
                            .bold()
                            .frame(maxWidth: .infinity)
            
                            .background(
                                Rectangle()
                                    .frame(width: 800, height: 130)
                                    .foregroundColor(.black)
                                    .opacity(0.7)
                            )
                            
                            .edgesIgnoringSafeArea(.bottom)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal) // Aggiungi spazio ai lati della VStack
                .frame(height: geometry.size.height) // Fissa l'altezza della VStack a quella dello schermo
            }
            .background {
                FrameView(image: model.frame)
                    .ignoresSafeArea() // Ignora lo spazio sicuro
                    .accessibilityHidden(true)
            }
        }
        .onAppear() {
            if !started {
                started = true
                DispatchQueue.global(qos: .background).async(execute: startClassifying)
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
