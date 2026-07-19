import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/category.dart';
import '../../data/models/person.dart';
import 'glass_card.dart';

class PersonRow extends StatelessWidget {
  final Person person;
  final Category? category;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsapp;
  final VoidCallback? onFavoriteToggle;
  final Widget? trailing;

  const PersonRow({
    super.key,
    required this.person,
    this.category,
    this.onTap,
    this.onCall,
    this.onWhatsapp,
    this.onFavoriteToggle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          if (onFavoriteToggle != null)
            IconButton(
              icon: Icon(person.isFavorite ? Icons.star : Icons.star_border,
                  color: person.isFavorite ? Colors.amber : Colors.white38),
              onPressed: onFavoriteToggle,
            ),
          CircleAvatar(
            radius: 22,
            backgroundImage: person.photoPath != null ? FileImage(File(person.photoPath!)) : null,
            child: person.photoPath == null ? Text(person.fullName.characters.first) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (person.phone != null)
                  Text(person.phone!, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                Wrap(
                  spacing: 6,
                  children: [
                    Text('العائلة: ${person.familyMembersCount} أفراد',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    if (category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(category!.name, style: const TextStyle(fontSize: 10.5)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else ...[
            if (onWhatsapp != null)
              IconButton(icon: const Icon(Icons.chat, color: Colors.green), onPressed: onWhatsapp),
            if (onCall != null)
              IconButton(icon: Icon(Icons.call, color: Theme.of(context).colorScheme.primary), onPressed: onCall),
          ],
        ],
      ),
    );
  }
}
