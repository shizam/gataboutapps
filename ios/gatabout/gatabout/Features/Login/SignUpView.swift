import SwiftUI

struct SignUpView: View {
    let authService: any AuthServiceProtocol
    let userRepository: UserRepository
    @State private var viewModel: SignUpViewModel

    init(authService: any AuthServiceProtocol, userRepository: UserRepository) {
        self.authService = authService
        self.userRepository = userRepository
        _viewModel = State(initialValue: SignUpViewModel(authService: authService, userRepository: userRepository))
    }

    var body: some View {
        VStack(spacing: Sizes.spacing24) {
            Text("Create Account").font(.title.bold())

            VStack(spacing: Sizes.spacing16) {
                TextField("Display Name", text: $viewModel.displayName)
                    .textContentType(.name)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))

                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))

                SecureField("Password (6+ characters)", text: $viewModel.password)
                    .textContentType(.newPassword)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))
            }

            if let error = viewModel.errorMessage {
                Text(error).font(.caption).foregroundStyle(AppColors.error).multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.signUp() }
            } label: {
                Group {
                    if viewModel.isLoading { ProgressView() } else { Text("Create Account") }
                }
                .frame(maxWidth: .infinity).frame(height: Sizes.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || !viewModel.isValid)

            Spacer()
        }
        .padding(Sizes.spacing24)
        .navigationTitle("Sign Up")
    }
}
