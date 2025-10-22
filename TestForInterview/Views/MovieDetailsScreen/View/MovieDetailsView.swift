//
//  MovieDetailsView.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import SwiftUI

struct MovieDetailsView: View {
    
    @ObservedObject var viewModel: DetailsScreenViewModel
    
    var onBack: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(spacing: 0) {
                        Button(action: {
                            onBack?()
                        }) {
                            Image(uiImage: UIImage(resource: .chevronIcon).withRenderingMode(.alwaysTemplate))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.txt)
                                .padding(.leading, 16)
                                .padding(.trailing, 20)
                                .padding(.vertical, 5.5)
                        }
                    }
                    
                    Text(viewModel.details?.title ?? "N/A")
                        .font(.custom(.roboto(weight: .bold, size: 30)))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.top, 15)
                
                ScrollView {
                    if let details = viewModel.details {
                        VStack(spacing: 0) {
                            
                            AsyncWebImageView(url: details.fullPosterURL)
                                .frame(width: geometry.size.width-125, height: (geometry.size.width-125) * 357 / 250)
                                .clipped()
                                .cornerRadius(15)
                                .padding(.horizontal, 62.5)
                            
                            Text("Rating: \(details.ratingText)")
                                .padding(.top, 8)
                                .font(.custom(.roboto(weight: .medium, size: 10)))
                                .multilineTextAlignment(.center)
                            
                            Text(details.overview ?? "Empty overview")
                                .font(.custom(.roboto(weight: .regular, size: 12)))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                                .padding(.horizontal, 16)
                            
                            Text(details.formattedReleaseDate)
                                .font(.custom(.roboto(weight: .regular, size: 12)))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                                .padding(.horizontal, 16)
                            
                            Button(action: {
                                viewModel.toggleFavorite()
                            }) {
                                Text(viewModel.isFavorite ? "Remove from favorites" : "Add to favorites")
                                    .font(.custom(.roboto(weight: .semibold, size: 16)))
                                    .foregroundColor(ThemeManager.shared.current == .dark ?
                                                     (viewModel.isFavorite ? Color.txt : Color.bg) : (viewModel.isFavorite ? Color.txt : Color.mainBlack))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(viewModel.isFavorite ? Color.clear : Color.mainYellow)
                                    .cornerRadius(24)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(viewModel.isFavorite ? Color.txt : Color.clear, lineWidth: 2)
                                    )
                                    .padding(.top, 16)
                                    .padding(.bottom, 64)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.top, 24)
                
                Spacer()
            }
        }
    }
}

