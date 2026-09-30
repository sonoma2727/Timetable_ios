import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var model: AppModel
    @State private var account = ""
    @State private var password = ""
    @State private var remember = true
    @FocusState private var focused: Field?

    private enum Field {
        case account
        case password
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 4) {
                Text("课表")
                    .font(.system(size: 34, weight: .bold))
                Text("教务系统登录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
                .frame(height: 36)

            TextField("学号", text: $account)
                .keyboardType(.numberPad)
                .textContentType(.username)
                .focused($focused, equals: .account)
                .textFieldStyle(.roundedBorder)
                .disabled(model.loading)
                .onChange(of: account) { value in
                    let trimmed = value.trimmingCharacters(in: .whitespaces)
                    if trimmed != value { account = trimmed }
                }

            Spacer()
                .frame(height: 14)

            SecureField("密码", text: $password)
                .textContentType(.password)
                .focused($focused, equals: .password)
                .textFieldStyle(.roundedBorder)
                .disabled(model.loading)
                .submitLabel(.done)
                .onSubmit { submit() }

            Toggle("记住密码，下次自动登录", isOn: $remember)
                .disabled(model.loading)
                .padding(.top, 8)

            if let error = model.loginError {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.top, 8)
                    .multilineTextAlignment(.center)
            }

            Button(action: submit) {
                HStack(spacing: 8) {
                    if model.loading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("登录中…")
                    } else {
                        Text("登 录")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(disabled ? Color.gray.opacity(0.4) : Color.accentColor)
            )
            .disabled(disabled)
            .padding(.top, 24)

            Spacer()
                .frame(height: 24)

            Text("账号密码仅保存在本机，用于自动登录教务系统")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 28)
        .onAppear {
            if account.isEmpty {
                account = model.account
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    focused = nil
                }
            }
        }
    }

    private var disabled: Bool {
        model.loading || account.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty
    }

    private func submit() {
        focused = nil
        guard !disabled else { return }
        model.login(account: account, password: password, remember: remember)
    }
}
