import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                SAButton(text: "SwapToken") {
                    print("!!!!!")
                }
                
                SAButton(text: "RefreshToken") {
                    print("!!!!!")
                }
            }
            
            Text("AccessToken: ")
            Text("AccessToken: ")
            Text("AccessToken: ")
            Text("AccessToken: ")
            Text("AccessToken: ")
            Text("AccessToken: ")
            Text("AccessToken: ")
            Spacer()
            
        }
    }
}

struct SAButton: View {
    var text: String
    var action: () -> Void
    
    init(text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            self.action()
        }) {
            HStack {
                Text(text)
                    .font(.title)
                    .fontWeight(.semibold)
            }
            .padding()
            .font(.title)
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(20)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

