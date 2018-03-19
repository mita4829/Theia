//
//  FirstViewController.swift
//  Theia
//
//  Created by Michael Tang on 2/9/18.
//  Copyright © 2018 Michael Tang. All rights reserved.
//

import UIKit
import AVFoundation

/*A constant weight to determine which pixel is filled versus empty. Threshold takes on values in the range [0,1]
 The closer to 1, the more lenient the filter algorithm will be in allowing a pixel to be filled.
 */
let THRESHOLD:Double = 0.3
let CELL_SIZE:Int = 20

class FirstViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var previewView: UIImageView!
    
    var analysisAreaY:Double = 0
    
    let chart_:CGImage = UIImage(named: "chart")!.cgImage!
    var chart:[[UInt8]] = [[]]
    
    var userImage:[[UInt8]] = [[]]
    var userImageWidth:Int = 0
    var userImageHeight:Int = 0
    
    var recognizedText:String = ""
    
    let characterClass:[String] = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
                                   "0","1","2","3","4","5","6","7","8","9"]
    
    /*Given a CGImage, returns a [[UInt8]] matrix of the pixel values for a given threshold*/
    func CGImageToUInt8(cgImage image: CGImage, threshold: Double) -> ([[UInt8]], Int, Int)  {
        let width:Int = image.width
        let height:Int = image.height
        
        let provider = image.dataProvider!
        let providerData = provider.data
        let data = CFDataGetBytePtr(providerData)
        
        var channel:[[UInt8]] = [[UInt8]](repeatElement([UInt8](repeatElement(UInt8(0), count: width)), count: height))
        for i in 0..<height {
            for j in 0..<width {
                let pixelInfo: Int = ((Int(width) * Int(i)) + Int(j)) * 4
                let r:UInt8 = data![pixelInfo]
                let g:UInt8 = data![pixelInfo]
                let b:UInt8 = data![pixelInfo]
                //Equation from the weigthed grayscale method
                let intensity:Double = 0.299*Double(r) + 0.587*Double(g) + 0.114*Double(b)
                /*Use < for black text and > for white text*/
                if(intensity < threshold*255){
                    channel[i][j] = UInt8(1)
                }
            }
        }
        
        return (channel, width, height)
    }
    
    /*Button taking photo*/
    @IBAction func takePhoto(_ sender: Any) {
        if(UIImagePickerController.isSourceTypeAvailable(.camera)){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }else{
            print("This device does not have a camera.")
        }
    }
    
    @IBAction func analyzeSavedPhoto(_ sender: UIButton) {
        view.endEditing(true)
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        self.present(imagePicker,animated: true,completion: nil)
    }
    
    
    /*After a photo is taken, this function is called. */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedPhoto = info[UIImagePickerControllerOriginalImage] as? UIImage{
            self.previewView.image = selectedPhoto
            dismiss(animated: true, completion: {
                /*call text recognition here*/
                print("Calling recognition now")
                self.scaleImage(image: selectedPhoto, maxDimension: 512)
            })
        }
    }
    
    
    /*First scale down the image to increase the speed of character recognition*/
    func scaleImage(image img:UIImage, maxDimension:CGFloat){
        
        let maxDimension:CGFloat = maxDimension
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor:CGFloat
        
        if img.size.width > img.size.height {
            scaleFactor = img.size.height / img.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = img.size.width / img.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        img.draw(in: CGRect(x:0, y:0, width:scaledSize.width, height:scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        let (m,_,_) = CGImageToUInt8(cgImage: (scaledImage?.cgImage)!, threshold: THRESHOLD)
        userImage = m
        userImageWidth = Int(scaledSize.width)
        userImageHeight = Int(scaledSize.height)
        
        let (rowBound, rowPair, columnPair) = self.seperateCharacters()
        print(rowBound)
        print(rowPair)
        print(columnPair)
        
        if(rowPair.count != columnPair.count){
            let alert = UIAlertController(title: "Grouping of Characters Failed 😭", message: "Please try to keep the text leveled, and avoid rotation.", preferredStyle: UIAlertControllerStyle.alert)
            let cancel=UIAlertAction(title: "Okay", style:UIAlertActionStyle.cancel, handler: nil)
            alert.addAction(cancel)
            present(alert, animated: true, completion: nil)
            return
        }
        self.scaleNearest(rowPairs: rowPair, columnPairs: columnPair)
    }
    
    
    /*Helper function to resize seperated characters to square form using nearest-neighbor interpolation*/
    func scaleNearest(rowPairs: [(Int, Int)], columnPairs:[(Int, Int)]) -> Void {
        for character in 0..<rowPairs.count {
            let rowMin:Int = rowPairs[character].0
            let rowMax:Int = rowPairs[character].1
            let colMin:Int = columnPairs[character].0
            let colMax:Int = columnPairs[character].1
            
            /*Attribute recognition for spaces*/
            if(character - 1 >= 0){
                if(colMin - columnPairs[character-1].1 > 20){
                    self.recognizedText += " "
                }
            }
            
            let x:Int = rowMax-rowMin
            let y:Int = colMax-colMin
            
            let x_factor:Double = Double(CELL_SIZE)/Double(x)
            let y_factor:Double = Double(CELL_SIZE)/Double(y)
            
            let x_scaled:Double = Double(x)*x_factor
            let y_scaled:Double = Double(y)*y_factor
            
            /*Catch division by zero*/
            if(x == 0 || y == 0){
                let alert = UIAlertController(title: "Classification of Characters Failed 😭", message: "Please try to keep the text leveled, and avoid rotation.", preferredStyle: UIAlertControllerStyle.alert)
                let cancel=UIAlertAction(title: "Okay", style:UIAlertActionStyle.cancel, handler: nil)
                alert.addAction(cancel)
                present(alert, animated: true, completion: nil)
                self.recognizedText = ""
                return
            }
            
            var mask:[[UInt8]] = [[UInt8]](repeatElement([UInt8](repeatElement(UInt8(0), count: CELL_SIZE)), count: CELL_SIZE))
            for row in 0..<CELL_SIZE {
                let x_ratio:Int = Int((Double(row)/x_scaled)*Double(x))
                for col in 0..<CELL_SIZE {
                    let y_ratio:Int = Int((Double(col)/y_scaled)*Double(y))
                    /*Reset mask for reuse*/
                    mask[row][col] = 0
                    mask[row][col] = userImage[x_ratio+rowMin][y_ratio+colMin]
                    //print(mask[row][col],terminator:"")
                }
                //print("")
            }
            /*Pass mask here for character classifcation*/
            
            //print("Matched: \(classification(matrix: mask))")
            self.recognizedText += classification(matrix: mask)
        }
        performSegue(withIdentifier: "opticalReminder", sender: SecondViewController.self)
        //print(self.recognizedText)
        self.recognizedText = ""
    }
    
    func classification(matrix m:[[UInt8]]) -> String{
        /*compare each character in the character class and find the highest match*/
        var highestMatch:Double = -1
        var highestMatchCharacter:String = ""
        var current:Double = 0

        for character in 0..<characterClass.count {
            for row in 0..<CELL_SIZE {
                for col in 0..<CELL_SIZE {
                    let calcCol = col+(character*CELL_SIZE)
                    if(m[row][col] == chart[row][calcCol]){
                        current += 1.0
                    }else{
                        current -= 1.25
                    }
                }
            }
            if(current > highestMatch){
                highestMatch = current
                highestMatchCharacter = characterClass[character]
            }
            current = 0
        }
        /*Uncomment the following code for much stronger recognition. This might take more computation power since it will take more time searching through previously learned characters the user took.*/
        let (highestMatchCharFromLearnedSet, score) = classifyFromLearnedSet(matrix: m)
        if(score > highestMatch){
            print("Prefered set \(score) > \(highestMatch) for \(highestMatchCharFromLearnedSet) against \(highestMatchCharacter)")
            highestMatchCharacter = highestMatchCharFromLearnedSet
        }
        /*Add matrix to the learning model, so it can become a scary-evil AI that can read only captial-handwritten text 😳 */
        correctMatrices.append(m)
        
        return highestMatchCharacter
    }
    
    /*Algorithm to group cluster of pixels into sets of characters. Returns the upperbound of the row range of a given sentence as a tuple, an array of row pairs, and an array of column pairs.*/
    func seperateCharacters() -> ((Int, Int), [(Int, Int)], [(Int, Int)]) {
        /*
         Detect the first instance of a filled pixel to find the values of e.g. a,b,c,d for a character "A", to define a cluster region. 
                /\  (c,d)
               /__\
              /    \
          (a,b)
         
         */
        var columnPairs:[(Int, Int)] = []
        var rowPairs:[(Int, Int)] = []
        var rowBound:(Int, Int)
        
        /*Find vertical distance*/
        var first:Int = -1
        var last:Int = userImageHeight
        
        for row in 0..<userImageHeight {
            var found:Bool = false
            for col in 0..<userImageWidth {
                if(userImage[row][col] == 1){
                    if(first == -1){
                        first = row
                    }
                    found = true
                    continue
                }
            }
            if(!found && first >= 0){
                last = row
                break
            }
        }
        rowBound = (first, last)
        
        first = -1
        last = userImageWidth
        /*Find horizontal distances pairs*/
        for col in 0..<userImageWidth {
            var found:Bool = false
            for row in rowBound.0..<rowBound.1 {
                if(userImage[row][col] == 1){
                    if(first == -1){
                        first = col
                    }
                    found = true
                    continue
                }
            }
            if((!found) && (first >= 0)){
                last = col
                columnPairs.append( (first, last) )
                first = -1
            }
        }
        /*Second filter to reduce vertical distance*/
        /*For each row pair, reduce the column size*/
        first = -1
        last = rowBound.1
        for detectedChar in 0 ..< columnPairs.count {
            for row in rowBound.0 ..< rowBound.1 {
                var found:Bool = false
                for col in columnPairs[detectedChar].0 ..< columnPairs[detectedChar].1 {
                    if(userImage[row][col] == 1){
                        if(first == -1){
                            first = row
                        }
                        found = true
                        continue
                    }
                }
                if((!found || row == (rowBound.1 - 1)) && first >= 0){
                    last = row
                    rowPairs.append( (first, last) )
                    first = -1
                }
            }
        }
        return (rowBound, rowPairs, columnPairs)
    }
    
    /*Sending recognized text from first vc to new reminder vc*/
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "opticalReminder"){
            let vc = segue.destination as! NewReminderViewController
            vc.eventTitleFromSegue = self.recognizedText
        }
    }
    
    @IBAction func unwindSegue(_ segue:UIStoryboardSegue){
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        /*Set the initial aspect ratio*/
        self.previewView.contentMode = .scaleAspectFill
        (chart, _, _) = CGImageToUInt8(cgImage: self.chart_, threshold: THRESHOLD)
        
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


