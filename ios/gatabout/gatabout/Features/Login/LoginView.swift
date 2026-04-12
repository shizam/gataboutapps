import SwiftUI

struct LoginView: View {
    let authService: any AuthServiceProtocol
    let userRepository: UserRepository
    @State private var viewModel: LoginViewModel

    init(authService: any AuthServiceProtocol, userRepository: UserRepository) {
        self.authService = authService
        self.userRepository = userRepository
        _viewModel = State(initialValue: LoginViewModel(authService: authService, userRepository: userRepository))
    }

    var body: some View {
        VStack(spacing: Sizes.spacing24) {
            Spacer()
            Text("gatabout").font(.largeTitle.bold())
            Text("Find your people, find your plans")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()

            VStack(spacing: Sizes.spacing16) {
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))
            }

            if let error = viewModel.errorMessage {
                Text(error).font(.caption).foregroundStyle(AppColors.error).multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.signIn() }
            } label: {
                Group {
                    if viewModel.isLoading { ProgressView() } else { Text("Sign In") }
                }
                .frame(maxWidth: .infinity).frame(height: Sizes.buttonHeight)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || !viewModel.isValid)

            NavigationLink("Forgot Password?") {
                ForgotPasswordView(authService: authService)
            }.font(.footnote)

            Spacer()

            NavigationLink {
                SignUpView(authService: authService, userRepository: userRepository)
            } label: {
                Text("Don't have an account? ").foregroundStyle(.secondary)
                + Text("Sign Up").bold()
            }.font(.subheadline)
        }
        .padding(Sizes.spacing24)
        .navigationBarBackButtonHidden()
    }
}
