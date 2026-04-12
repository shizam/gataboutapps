import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel

    init(authService: AuthService) {
        _viewModel = State(initialValue: LoginViewModel(authService: authService))
    }

    var body: some View {
        VStack(spacing: Sizes.spacing24) {
            Spacer()

            Text("gatabout")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: Sizes.spacing16) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(height: Sizes.textFieldHeight)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .frame(height: Sizes.textFieldHeight)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.signIn() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: Sizes.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isFormValid || viewModel.isLoading)

            Spacer()
        }
        .padding(.horizontal, Sizes.padding24)
    }
}
