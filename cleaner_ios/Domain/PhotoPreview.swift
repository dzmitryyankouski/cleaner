import Foundation
import Observation
import SwiftUI

@Observable
class PhotoPreview {
    var photo: PhotoModel?
    var photos: [PhotoModel] = []
    var index: Int?
    var isPresented: Bool = false

    func show(photos: [PhotoModel], item: PhotoModel) {
        self.photos = photos
        self.index = photos.firstIndex(of: item)
        self.photo = item
        isPresented = true
    }

    func hide() {
        photos = []
        index = nil
        isPresented = false
    }
}
