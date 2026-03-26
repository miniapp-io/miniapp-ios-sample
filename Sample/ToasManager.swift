//
//  ToasManager.swift
//  Sample
//
//

import UIKit

class ToastManager {
    static let shared = ToastManager()
    
    private var toastView: ToastView?
    
    private init() {}
    
    func showToast(message: String,
                   duration: TimeInterval = 2.0,
                   position: ToastPosition = .bottom,
                   in viewController: UIViewController? = nil) {
        
        DispatchQueue.main.async {
            self.toastView?.removeFromSuperview()
            
            let toastView = ToastView(message: message)
            self.toastView = toastView
            
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
            
            window.addSubview(toastView)
            
            toastView.translatesAutoresizingMaskIntoConstraints = false
            
            let centerXConstraint = toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor)
            let widthConstraint = toastView.widthAnchor.constraint(lessThanOrEqualToConstant: window.bounds.width * 0.8)
            
            let positionConstraint: NSLayoutConstraint
            switch position {
            case .top:
                let topPadding = window.safeAreaInsets.top + 20
                positionConstraint = toastView.topAnchor.constraint(equalTo: window.topAnchor, constant: topPadding)
            case .center:
                positionConstraint = toastView.centerYAnchor.constraint(equalTo: window.centerYAnchor)
            case .bottom:
                let bottomPadding = window.safeAreaInsets.bottom + 100
                positionConstraint = toastView.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -bottomPadding)
            }
            
            NSLayoutConstraint.activate([
                centerXConstraint,
                widthConstraint,
                positionConstraint
            ])
            
            toastView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                toastView.alpha = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                UIView.animate(withDuration: 0.3, animations: {
                    toastView.alpha = 0
                }, completion: { _ in
                    toastView.removeFromSuperview()
                    if self.toastView === toastView {
                        self.toastView = nil
                    }
                })
            }
        }
    }
    
    enum ToastPosition {
        case top
        case center
        case bottom
    }
}

class ToastView: UIView {
    private let messageLabel: UILabel
    
    init(message: String) {
        self.messageLabel = UILabel()
        super.init(frame: .zero)
        
        setupUI()
        messageLabel.text = message
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layer.cornerRadius = 8
        clipsToBounds = true
        
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        addSubview(messageLabel)
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
}
