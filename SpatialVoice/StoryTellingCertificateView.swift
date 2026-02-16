// StoryTellingCertificateView.swift
import SwiftUI

struct StoryTellingCertificateView: View {
    @Binding var isRootPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showDownloadAlert = false
    @State private var showLinkedInAlert = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 10/255, green: 8/255, blue: 30/255),
                    Color(red: 30/255, green: 18/255, blue: 60/255),
                    Color(red: 15/255, green: 10/255, blue: 40/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Congrats header
                    VStack(spacing: 10) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                            )

                        Text("Certificate Earned! 🎉")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text("Story Telling — Level 1 • Beginner")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 40)

                    // Certificate image
                    Image("Certificates_pic1_1_Pass")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 700)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .yellow.opacity(0.25), radius: 20, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.5), .orange.opacity(0.3), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )

                    // Action buttons
                    VStack(spacing: 14) {
                        // Download button
                        Button {
                            showDownloadAlert = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title2)
                                Text("Download Certificate")
                                    .font(.title3.weight(.bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: 500)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.3, green: 0.3, blue: 0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)

                        // LinkedIn button
                        Button {
                            showLinkedInAlert = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "link.circle.fill")
                                    .font(.title2)
                                Text("Add to LinkedIn")
                                    .font(.title3.weight(.bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: 500)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.47, blue: 0.71), Color(red: 0.0, green: 0.35, blue: 0.55)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer().frame(height: 10)
                }
                .frame(maxWidth: .infinity)
            }

            // Back to Home (top-right corner)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isRootPresented = false
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
        .alert("Coming Soon", isPresented: $showDownloadAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The download feature will be available in a future update.")
        }
        .alert("Coming Soon", isPresented: $showLinkedInAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("LinkedIn integration will be available in a future update.")
        }
    }
}
