import SwiftUI

struct ForgotPasswordView: View {
    @State private var viewModel: ForgotPasswordViewModel

    init(authService: any AuthServiceProtocol) {
        _viewModel = State(initialValue: ForgotPasswordViewModel(authService: authService))
    }

    var body: some View {
        VStack(spacing: Sizes.spacing24) {
            if viewModel.didSendReset {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: Sizes.spacing48))
                    .foregroundStyle(AppColors.primary)
                Text("Check Your Email").font(.title2.bold())
                Text("We sent a password reset link to \(viewModel.email)")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            } else {
                Text("Reset Password").font(.title2.bold())
                Text("Enter your email and we'll send you a reset link")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)

                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(Sizes.spacing12)
                    .background(AppColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadius8))

                if let error = viewModel.errorMessage {
                    Text(error).font(.caption).foregroundStyle(AppColors.error)
                }

                Button {
                    Task { await viewModel.resetPassword() }
                } label: {
                    Group {
                        if viewModel.isLoading { ProgressView() } else { Text("Send Reset Link") }
                    }
                    .frame(maxWidth: .infinity).frame(height: Sizes.buttonHeight)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || !viewModel.isValid)
            }
            Spacer()
        }
        .padding(Sizes.spacing24)
        .navigationTitle("Forgot Password")
    }
}
